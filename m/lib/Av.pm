package Av;
use Mojo::Base 'Mojolicious';
use DBI;
#use strict;

has 'bold_dates' => 2;
has 'dbh_av2' => sub {
    my $self = shift;
    my $dbh = DBI->connect(
        "DBI:mysql:database=av2_kiev;host=127.0.0.1",
        'root',
        '',
        {
    #        mysql_enable_utf8 => 1,
            AutoCommit => 1,
            RaiseError=> 1,
            PrintError => 1,
            mysql_auto_reconnect => 1,
        }
    ) or die "Cannot connect: " . $DBI::errstr;
    return $dbh;
};

sub startup {
    my $self = shift;

    # $self->plugin('DefaultHelpers');
    $self->app->dbh_av2->do('SET NAMES utf8');

    $self->helper( debug => sub {
      my ($c, $str) = @_;
      $c->app->log->debug($str);
    });

    #$self->app->log->debug ( "*** Start");

    my $r = $self->routes;
    #my $example = $r->route('/example')->to('example#')->name('EX');
# here
    $r->get('/')->to('index#index')->name('index');
    #$r->any([qw/GET/]=>'/a/(:report)')->to('index#detalize')->name('detalize');
    $r->get('/a/(:report)',{report=>undef})->to('index#detalize')->name('detalize');

    $r->get('/history')->to('index#history')->name('history');
    $r->get('/vklogin')->to('index#vklogin')->name('vklogin');
    $r->get('/contacts')->to('index#contacts')->name('contacts');
    $r->get('/oauth2callback')->to('index#oauth2callback')->name('oauth2callback');
    $r->post('/liqpay')->to('index#liqpay')->name('liqpay');

    $r->get('/lp1')->to('index#lp1')->name('lp1'); ## ??

    ## redirect с формы API url магазина кл-сер
    ## первоочередной
    $r->get('/after_liqpay')->to('index#after_liqpay')->name('after_liqpay'); 

}

1;
