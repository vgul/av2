package Av::Index;
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;
use Data::Printer;
use Mojo::Util qw(url_escape);
use Encode;
use LWP::UserAgent;
use HTTP::Request;
use Digest::SHA1 qw/sha1/;
use MIME::Base64 qw/encode_base64/;

use strict;

my $title='Недвижимость из 1х рук/в 1е руки г.Киев';

sub index {
    my $self = shift;

#$self->show_p;
$self->how_old_prod;

    #say 'test: ', $self->config('test');
    #say 'home: ', $self->config('home');
    say 'home: ', $self->config('some');
    #$self->render( begin1 => "<span color='green'>begin render</span>",
    #        format=>'html' );

#    $self->render( template=>'index/index0', layout=>'layout0' );
    $self->render( title=>$title );
}

sub detalize {
    my $self = shift;
    my $sess_debug;

if(0) {
$sess_debug = '           '. time. "\n";
$sess_debug .= Dumper $self->session('p');
$sess_debug .= '<hr/>';
my $conf = $self->conf_prod_age;
my $curr = $self->how_old_prod;
$sess_debug .= 'Conf prod_age:'. $self->conf_prod_age. " as constand\n";
$sess_debug .= 'How old prod: '. $self->how_old_prod. " calculate from cur time\n";
$sess_debug .= 'diff:         '. ($conf - $curr). " REST ". ($conf-$curr)/60 ."\n";
$sess_debug .= 'is_prod: '. $self->is_prod. "\n";
$sess_debug .= 'is_demo: '. $self->is_demo. "\n";
}
    my $report = $self->param('report');
    my $home = $self->app->home;
    my $fixtures_path = $home.'/templates/';
    my $fixture       = 'index/fixtures/'.$self->region.'/data/';
    $fixture .= 'demo/' if $self->is_demo;
    $fixture .= 'prod/' if $self->is_prod;
    
    $self->info ( 'Detalize: '.  $report );
    #$self->app->log->debug ( 'Home: '.  $home  );
    #$self->app->log->info ( 'fixtures: '.  $fixture  );
    #$self->info ( 'Detalize: '.  $fixtures_path.$fixture.$report.'.html.ep'  );
    unless ($report) {
        $self->redirect_to( "/" );
        return 1;
    }

    if( -f $fixtures_path.$fixture.$report.'.html.ep') {
        ### ??? WHY RENDERING ???
        #my $av2data = $self->render( $fixture.$report, 'mojo.to_string'=>1 );
        my $av2data = `cat ${fixtures_path}${fixture}${report}.html.ep`;

        $self->render( title=>$title, av2data=>decode('utf8',$av2data)
        ,sess_debug=>$sess_debug );

    } else {
        $self->redirect_to( $self->url_for('index' ));
    }

}

sub payment_data {
    my $self = shift;
    my $p = shift;
    my $order_id = $p->{order_id};
    my $test = $self->sandbox_payment;
    my %data = (
         payment_form_action=>'https://www.liqpay.com/api/pay'
        ,payment_public_key=>'i71804176847'
        ,payment_amount=>'0.10'
        ,payment_currency=>'UAH'
        #,payment_description=>encode('cp1251','Информационные услуги')
        #,payment_description=>encode('utf8','Информационные услуги')
        ,payment_description=>'Information Service'
        ,payment_type=>'buy'
        ,payment_order_id=>$order_id
        ,payment_pay_way=>'card,delayed'
        ,payment_language=>'ru'
        ,payment_sandbox=>$test,
        ,payment_server_url=>$self->req->url->base.'/liqpay'
        ,payment_result_url=>$self->req->url->base.'/after_liqpay?'.$order_id
        ,private_key=>'X4cne5QJAu5al2DoePx5KMCp0oOCy5bDUqtby4DJ'
    );
    #,payment_signature=>'Vlad'

    # https://github.com/liqpay/sdk-perl/blob/master/Liqpay.pm
    my $signature;
    grep { $signature .= $data{$_} } qw/
           private_key         payment_amount     payment_currency   
           payment_public_key  payment_order_id   payment_type
           payment_description payment_result_url payment_server_url /;
   
    delete $data{private_key};
    my $ready = encode_base64(sha1($signature));
    chop( $ready );
    $data{payment_signature} = $ready;
    return ( %data );
}

sub get_liqpay_button {
    my $self = shift;
    my $info  = $self->param('info');
    my $ad_id = $self->param('ad_id_start');
    $self->info("GLB: ad_id: '$ad_id', Info: '$info'");
    my $order_id = (map{$_->[0]}@{$self->app->dbh_av2_clients->selectall_arrayref('select max(id) from orders')})[0];
    ## KIEV kiev
    $order_id=++${order_id}.substr($self->region,0,1).'-'.substr(time,-4);
    my $insert = $self->app->dbh_av2_clients->do(
      "INSERT INTO orders SET order_id='$order_id' ".
            ($ad_id ? ",ad_id=$ad_id":''). 
            ($info ?  ",info='$info'":'') );
   
    $self->info("GLB: Prepared order '$order_id'. Insert return: $insert" );
    my %payment_data = payment_data($self, {order_id=>$order_id} );
 
    my $button = $self->render( 'index/includes/liqpay_button', %payment_data, 'mojo.to_string'=>1  );

    $self->render(text=>$button);
}

sub after_liqpay {
    my $self = shift;
    my @params = $self->param();
    my $order_id = $params[0];
    #$self->app->log->debug ( "after_liqpay params: ". join(',',@params ));
    foreach my $p ( @params ) {
        $self->info ( 'AfterLiqpay: '.$p. ': '.  $self->param($p) );
    }
    my @data = @{ $self->app->dbh_av2_clients->selectall_arrayref(
        'SELECT status, info, date2, amount, UNIX_TIMESTAMP(date2)'.
        "FROM orders WHERE order_id='$order_id' ORDER BY date2 DESC")};
    ## WARN
    $self->app->log->error("*** ORDERID $order_id. More than one record")  
                                                if scalar @data >1;
    my $status     = $data[0]->[0];
    my $info       = $data[0]->[1];
    my $stamp      = $data[0]->[2];
    my $amount     = $data[0]->[3];
    my $unix_stamp = $data[0]->[4];

    my $pay_sheet = $self->session('p');
    $pay_sheet->{$unix_stamp} = {id=>$order_id,sum=>$amount};

    my @dates = reverse sort keys %{ $pay_sheet };
    #say "DATES: \n".join "\n", @dates;
    for(my $i=$self->config->{how_many_dates_save}; $i<scalar @dates; $i++ ) {
        #say "DELETE: ". $dates[$i];
        delete $pay_sheet->{$dates[$i]};
    }
    $self->session(p=>$pay_sheet); # date2

    $self->info("After liqpay: Order_id: $order_id, Status: $status, Info: $info");
    $self->redirect_to($self->url_for('detalize').$info.'.html');
}

sub liqpay {
    my $self = shift;
    my @params = $self->param();
    #$self->app->log->debug ( "params: ". join(',',@params ));
    foreach my $p ( @params ) {
        $self->info ( 'LIQPAY: '. $p. ': '.  $self->param($p) );
    }
    my $sql = 'UPDATE orders SET '.
        ' amount   =   '. $self->param('amount'). "\n".
        ',minus    =   '. $self->param('receiver_commission'). "\n".
        ',phone    = \''. $self->param('sender_phone'). '\''. "\n".
        ',status   = \''. $self->param('status'). '\''. "\n".
        ',tran_id  =   '. $self->param('transaction_id'). "\n".
        ',type     = \''. $self->param('type'). '\''. "\n".
        ',date1    = date1'. "\n".
        ',date2    = NOW()'. "\n".
        'WHERE order_id = \''. $self->param('order_id'). '\'';
    my $update = $self->app->dbh_av2_clients->do( $sql );
    $self->debug( "LIQPAY. I update my db. Status: $update" );
    $self->render(text=>'');
    return 1;
}

sub oauth2callback_to_del {
    my $self = shift;
    my @params = $self->param();
    my $code = $self->param('code');
    $self->app->log->debug ( "params: ". join(',',@params ));
    $self->app->log->debug ( "code: ". $code );

    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME}=0;
    my $ua = LWP::UserAgent->new(timeout => 20, ssl_opts => { verify_hostname => 0 });

    my $url = 'https://accounts.google.com/o/oauth2/token';
    my $redirect_uri = url_escape('http://k116.asuscomm.com:3000/oauth2callback');
    my $req = HTTP::Request->new('POST',$url);
    $req->header('Content-Type' => 'application/x-www-form-urlencoded');
    my $content = sprintf("code=%s", $code)
      ."&grant_type=authorization_code"
      ."&cliend_id=964397194725-pkanvp4cqf9ga2l6r6spcrqvenh7dpnl.apps.googleusercontent.com"
      ."&cliend_secret=oRh6v8dBLrrZK6Hlmlf0d8tt"
      ."&redirect_uri=$redirect_uri";
    #$req->content(url_escape($content));
    $req->content($content);
    my $response = $ua->request($req);
    $self->app->log->debug ( "req: ". Dumper $req );
    $self->app->log->debug ( "response: ". Dumper $response );
    
    $self->redirect_to('/');
}

sub oauth2callback {
    my $self = shift;
    my @params = $self->param();
    my $code = $self->param('code');
    $self->app->log->debug ( "params: ". join(',',@params ));
    $self->app->log->debug ( "code: ". $code );

    my $tx = $self->app->ua->post('https://accounts.google.com/o/oauth2/token' => 
        #{   #'Content-type' => 'application/x-www-form-urlencoded',
        #    'accept' => undef,
        #    'aonnection' => undef, 
        #    'accept-encoding' => '', 
        #    'user-agent' => undef
        #} => 
        form => {
        code => $code
        ,client_id=>'964397194725-pkanvp4cqf9ga2l6r6spcrqvenh7dpnl.apps.googleusercontent.com'
        ,client_secret=>'oRh6v8dBLrrZK6Hlmlf0d8tt'
        ,redirect_uri=>'http://k116.asuscomm.com:3000/oauth2callback'
        ,grant_type=>'authorization_code'
    });

    #$self->app->log->debug ( "dump: ". Dumper $tx );

        if (my $res = $tx->success) { 
          #say "here7777: ", $res->body;
            my $token = $res->json->{access_token};
            $self->session->{access_token} = $token;
            say 'Got: ', $token;
            $self->redirect_to('/contacts');
            return 1;
        } else {
          my $err = $tx->error;
          die "$err->{code} response: $err->{message}" if $err->{code};
          die "Connection error: $err->{message}";
        }

    $self->redirect_to('/');
}

sub contacts {
    my $self = shift;
say "Me here0";

    # Read access token from session
    my $a_token = $self->session->{access_token} or die "No access token!";

    #my $q = "https://www.googleapis.com/auth/userinfo.email";
    #my $q = "https://www.google.com/m8/feeds/contacts/default/full";
    my $q = "https://www.googleapis.com/oauth2/v1/userinfo?access_token=$a_token";
        #/contacts/default/full/?alt=json&max-results=3000"
    # Get the contacts
    my $c_res = $self->app->ua->get(
        $q # ."/?alt=json&max-results=30"
        #"$config->{scope}$config->{contacts_full}",
        #, { Authorization => "Bearer $a_token" }
    );

    $self->app->log->debug ( "dump: ". Dumper $c_res );
    
#    die 'Error'  unless $c_res->res->is_status_class(200);

#    $self->render( html=>Dumper $c_res );
#say "UEINFO", $c_res->{userinfo.email};
    #$self->stash( contacts => $c_res->json->{feed}{entry} );
    $self->redirect_to('/');
}

sub vklogin {
    my $self = shift;

    my @params = $self->param();
    my $code = $self->param('code');
    $self->app->log->debug ( "params: ". join(',',@params ));

    ## http://habrahabr.ru/post/145988/
    ## http://vk.com/editapp?id=4650321&section=options
    ## http://vk.com/editapp?act=create&site=1

    #my $res=$self->app->ua->max_redirects(5)->get("https://oauth.vk.com/access_token&client_id=4650321&client_secret=rV845hoyvb6tqpgYsXqv&code=${code}")->res;

    my $query = "https://oauth.vk.com?client_id=4650922&client_secret=UYDvNJtqIIMp4q599bHR&code=${code}&redirect_uri=http://k116.asuscomm.com:3000/vklogin"; 
    $self->app->log->debug ( "code: ". $code );
    $self->app->log->debug ( "query: ". $query );
    my $res=$self->app->ua->get($query); #->res;
    

    #$self->app->log->debug ( "is_status_class: ". $res->success );
    $self->app->log->debug ( "res body: ". Dumper $res );
    $self->app->log->debug ( "res error: ". $res->error->{message} );
    $self->redirect_to('/');
    return 1;
}

my @a = qw/янв фев мар апр май июн июл авг сен окт ноя дек /;
sub date {
    my $s = shift;
    my ($y,$m,$d) = split /-/, $s;
    return $d.$a[$m-1];
}
sub human_phone {
    my $p = shift;
    my @a = map {
        '(0'.substr($_,0,2).') '.substr($_,2,3).'-'.
                substr($_,5,2).'-'.substr($_,7);
    } split /,/, $p;
    return join ', ',@a;
}

my @bold_dates;
sub history {
    my $self = shift;
    my $ad_id_start = $self->param('ad_id');
    $self->info ( "History: ad_id_start: ". $ad_id_start );

    ## WHERE AM I
    #my $endpoint_split = $self->req->url->to_abs->path->parts;
    #$self->app->log->debug ( "fff: ". Dumper $endpoint_split );

    my $retro = $self->app->dbh_av2->selectall_arrayref(
        'select '. "\n".
        '    idate '. "\n".
        '    ,body '. "\n".
        '    ,hier '. "\n".
        '    ,phones_to_page '. "\n".
        'FROM av2data '. "\n".
        "WHERE ad_id_start = $ad_id_start ". "\n".
        "ORDER BY idate DESC ". "\n".
        '-- limit 1 '
    );
    my $first=1;
    my $phones_to_page;
    ## calculate dates array
    my @dates = map { $_->[0] } 
        @{ $self->app->dbh_av2->selectall_arrayref(
            'select idate from av2data '.
            'group by idate order by idate DESC ') };
    @bold_dates = @dates[0..$self->config->{bold_dates}-1];
    ## end calculate
    my @ad_dates;
    foreach my $a ( @{ $retro } ) {
        push @ad_dates, $a->[0];
                       #bold_date(real=>$a->[0],
                       #     human=>date($a->[0]));
        $a->[1] = decode('utf8',$a->[1]);
        $a->[2] = decode('utf8',$a->[2]); ## hier
        if( $first ) {
            $phones_to_page = $a->[3]; ## phones_to_page
            undef $first;
        }
    }

    my $show_liqpay_button;
    $show_liqpay_button = 1 if $self->is_demo and 
                      grep @ad_dates[0] eq $_, @bold_dates;

    my $history_data = $self->render('index/fixtures/retro',
            retro=>$retro, 
            ad_id_start=>$ad_id_start,
            bold_dates=>[@bold_dates],
            phones_to_page=>human_phone($phones_to_page),
            show_liqpay_button=>$show_liqpay_button,
            'mojo.to_string'=>1 ); 
    #$self->debug( "**** HData: ". $history_data );
    #$self->info("Dates: ". join ',', @ad_dates );
    #$self->info("Bold: ". join ',', @bold_dates );
    #$self->info('Hist: show_liqpay_button:'. $show_liqpay_button );
    $self->render( text => $history_data, ad_id_start=>$ad_id_start );
}

#sub bold_date {
#    my %p = @_; 
#    if( grep $_ eq $p{real}, @bold_dates ) {
#        return '<font color="green"><b>'.$p{human}.'</b></font>';
#    }
#    return $p{human};
#}


1;
