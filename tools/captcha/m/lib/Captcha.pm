package Captcha;
use Mojo::Base 'Mojolicious';
use Mojolicious::Plugin::Captcha;
use strict;

sub startup {
    my $self = shift;
    $self->app->log->debug ( "*** Start");

    $self->helper( debug => sub {
      my ($c, $str) = @_;
      $c->app->log->debug($str);
    });

    $self->plugin(
        'captcha',
        {
            session_name => 'captcha_string',
            out          => {force => 'jpeg'},
            #particle    => [0,0],
            particle     => [12,12],
            create       => [qw/normal rect #000000 #c8c8c8 /],
            'new'  =>                          {
                rnd_data        => [qw/0 1 2 3 4 5 6 7 9/],
                width           => 50,
                height          => 25,
                lines           => 1 
                ,gd_font         => 'giant'
                ,rndmax         => 3
                ,frame          => undef
               #,scramle         => 1,
            }
        }
    );

    my $r = $self->routes;
    #my $example = $r->route('/example')->to('example#')->name('EX');
# here
    $r->get('/')->to('index#index'); #->name('index');
    $r->get('/captcha')->to('index#captcha'); #->name('index');

}

1;
