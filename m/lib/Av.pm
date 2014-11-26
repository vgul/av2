package Av;
use Mojo::Base 'Mojolicious';

sub startup {
    my $self = shift;
    $self->app->log->debug ( "here");

    my $r = $self->routes;
    #my $example = $r->route('/example')->to('example#')->name('EX');
# here
    $r->get('/')->to('index#index'); #->name('index');
    $r->get('/history')->to('index#history')->name('history');
    $r->get('/vklogin')->to('index#vklogin')->name('vklogin');
    $r->get('/contacts')->to('index#contacts')->name('contacts');
    $r->get('/oauth2callback')->to('index#oauth2callback')->name('oauth2callback');

}

1;
