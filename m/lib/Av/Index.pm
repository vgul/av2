package Av::Index;
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;
use Mojo::Util qw(url_escape);
use LWP::UserAgent;
use HTTP::Request;
use strict;

sub index {
    my $self = shift;
 #   $self->render( text=>'here' );
}


sub check {
    my $self = shift;
    my $endpoint_split = $self->req->url->to_abs->path->parts;
    $self->app->log->debug ( "fff: ". $endpoint_split );
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

sub history {
    my $self = shift;
    my $ad_id = $self->param('ad_id');
    $self->app->log->debug ( "ad_id: ". $ad_id );
    $self->render( text=>
'
<div class="row row-centered">
<div class="col-md-12 ">


<table class="table table-condensed">
<tr>
    <td>20ноя</td>
    <td>*** MODAL Или двухкомн.кв. комнату, левый, правый берег. Только у собственника. Примем во внимание Ваши пожелания и требования. Срочно.</td>
</tr>

<tr> <td>20ноя</td>
    <td>Автовокзал, Академгородок, Беличи, Борщаговка, Виноградарь, Лесной массив, Лукьяновка, Нивки, Оболонь, Отрадный, Куреневка, Подол, Печерск, Русановка, Сырец, Троещина, Харьковский массив, Чоколовка, у хозяина. Рассмотрю все предложения.</td>
<tr>
</table>

Тел. (044) 3423423


</div> <!-- row -->
</div> <!-- col-md -->
' );
}
;1;
