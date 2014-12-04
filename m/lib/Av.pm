package Av;
use Mojo::Base 'Mojolicious';
use DBI;
#use strict;

use Helpers;
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
    #$self->app->dbh_av2->do('SET NAMES utf8');
    $dbh->do('SET NAMES utf8');
    return $dbh;
};

has 'dbh_av2_clients' => sub {
    my $self = shift;
    my $dbh = DBI->connect(
        "DBI:mysql:database=av2_clients;host=127.0.0.1",
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

    #$self->plugin('DefaultHelpers');
    #$self->app->dbh_av2->do('SET NAMES utf8');
    #$self->log->level('info');
    
    $self->helper( debug => sub {
        my ($c, $str) = @_;
        $c->app->log->debug($str);
    });

    my $config = $self->plugin('Config'); # => {file => 'ashafix.conf' });

    $self->helper( show_p       => sub { Helpers::show_p(@_) } );
    $self->helper( is_demo      => sub { Helpers::is_demo(@_) } );
    $self->helper( is_prod      => sub { Helpers::is_prod(@_) } );
    $self->helper( how_old_prod => sub { Helpers::how_old_prod(@_) } );
    $self->helper( region       => sub { Helpers::region(@_) } );

    $self->secrets(['Rolling stones']);
    $self->sessions->cookie_name('zvonar_av2');

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
    $r->get('/glb')->to('index#get_liqpay_button')->name('get_liqpay_button');
    $r->post('/liqpay')->to('index#liqpay')->name('liqpay');

    $r->get('/lp1')->to('index#lp1')->name('lp1'); ## ??

    ## redirect с формы API url магазина кл-сер
    ## первоочередной
    $r->get('/after_liqpay')->to('index#after_liqpay')->name('after_liqpay'); 

}

1;
