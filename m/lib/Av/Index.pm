package Av::Index;
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;
use Data::Printer;
use Mojo::Util qw(url_escape);
use Encode;
use LWP::UserAgent;
use HTTP::Request;
use strict;

my $title='Недвижимость из 1х рук/в 1е руки г.Киев';

sub index {
    my $self = shift;
    $self->app->log->debug ( 'Payd: '.  $self->session('paid') );
    
    #$self->render( begin1 => "<span color='green'>begin render</span>",
    #        format=>'html' );

#    $self->render( template=>'index/index0', layout=>'layout0' );
    $self->render( title=>$title );
}

sub detalize {
    my $self = shift;
    my $report = $self->param('report');
    my $home = $self->app->home;
    my $fixtures_path = $home.'/templates/';
    my $fixture       = 'index/fixtures/'.'kiev'.'/data/demo/';
    
    $self->app->log->debug ( 'Report: '.  $report );
    $self->app->log->debug ( 'Home: '.  $home  );
    $self->app->log->debug ( 'fixtures: '.  $fixture  );
    $self->app->log->debug ( 'ready: '.  $fixtures_path.$fixture.$report.'.html.ep'  );
    unless ($report) {
        $self->redirect_to( "/" );
        return 1;
    }

    if( -f $fixtures_path.$fixture.$report.'.html.ep') {
        ### ??? WHY RENDERING ???
        #my $av2data = $self->render( $fixture.$report, 'mojo.to_string'=>1 );
        my $av2data = `cat ${fixtures_path}${fixture}${report}.html.ep`;
        $self->render( title=>$title, av2data=>decode('utf8',$av2data) );
    } else {
        $self->redirect_to( 'index' );
    }

}

sub after_liqpay {
    my $self = shift;
    my @params = $self->param();
    $self->app->log->debug ( "after_liqpay params: ". join(',',@params ));
    foreach my $p ( @params ) {
        $self->app->log->debug ( $p. ': '.  $self->param($p) );
    }
    $self->redirect_to('/');
}

sub liqpay {
    my $self = shift;
    my @params = $self->param();
    $self->app->log->debug ( "params: ". join(',',@params ));
    foreach my $p ( @params ) {
        $self->app->log->debug ( $p. ': '.  $self->param($p) );
    }
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
    #$self->app->log->debug ( "ad_id_start: ". $ad_id_start );

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
            'group by idate order by idate desc ') };
    @bold_dates = @dates[0..$self->app->bold_dates-1];
    ## end calculate
    foreach my $a ( @{ $retro } ) {
        $a->[0] = bold_date(real=>$a->[0],
                            human=>date($a->[0]));
        $a->[1] = decode('utf8',$a->[1]);
        $a->[2] = decode('utf8',$a->[2]); ## hier
        if( $first ) {
            $phones_to_page = $a->[3]; ## phones_to_page
            undef $first;
        }
    }
    #$self->debug( "**** Data: ". p $retro );
    #$self->render(text=>'here');  
    #return 1;
    my $history_data = $self->render('index/fixtures/retro',
            retro=>$retro, 
            ad_id_start=>$ad_id_start,
            phones_to_page=>human_phone($phones_to_page),
            'mojo.to_string'=>1 ); 
    #$self->debug( "**** HData: ". $history_data );

    $self->render( text => $history_data, ad_id_start=>$ad_id_start );
}

sub bold_date {
    my %p = @_; 
    if( grep $_ eq $p{real}, @bold_dates ) {
        return '<b>'.$p{human}.'</b>';
    }
    return $p{human};
}


;1;
