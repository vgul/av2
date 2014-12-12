package Av;
use Mojo::Base 'Mojolicious';
use DBI;
use Data::Dumper;
#use strict;

use Helpers;
has 'dbh_av2' => sub {
    my $self = shift;
    my $dbh = DBI->connect(
        "DBI:mysql:database=aviso2;host=127.0.0.1",
        'root',
        '',
        {
            mysql_enable_utf8 => 1,
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
    $self->plugin('RemoteAddr');

    #$self->session(expiration=>60*60*24*14);
    #$self->session(expires=>time+60*60*24*14);
    #$self->plugin('DefaultHelpers');
    #$self->app->dbh_av2->do('SET NAMES utf8');
    
    $self->helper( debug => sub { my($c,$str)= @_; $c->app->log->debug($str); });
    $self->helper( info  => sub { my($c,$str)= @_; $c->app->log->info($str); });

    my $config = $self->plugin('Config'); # => {file => 'ashafix.conf' });

    # if empty - debug. or info
    $self->log->level($config->{log_level}) if exists $config->{log_level};

    $self->secrets(['Rolling stones']);
    $self->sessions->cookie_name('zvonar_av2');
    $self->sessions->default_expiration($self->config->{default_expiration});

    $self->helper( is_demo         => sub { Helpers::is_demo(@_) } );
    $self->helper( is_prod         => sub { Helpers::is_prod(@_) } );
    $self->helper( how_old_prod    => sub { Helpers::how_old_prod(@_) } );
    $self->helper( conf_prod_age   => sub { Helpers::conf_prod_age(@_) } );
    $self->helper( region          => sub { Helpers::region(@_) } );
    $self->helper( index_subtext   => sub { Helpers::index_subtext(@_) } );
    $self->helper( sandbox_payment => sub { Helpers::sandbox_payment(@_) } );
    $self->helper( human_date      => sub { Helpers::human_date(@_) } );
    $self->helper( amount          => sub { Helpers::amount(@_) } );
    $self->helper( bold_dates      => sub { Helpers::bold_dates(@_) } );
    $self->helper( Region_cyr      => sub { Helpers::Region_cyr(@_) } );
    $self->helper( Region_cyr_short=> sub { Helpers::Region_cyr_short(@_) } );


    #$self->app->log->debug ( "*** Start");

    my $r = $self->routes;
    #my $example = $r->route('/example')->to('example#')->name('EX');
# here
    $r->get('/')->to('index#index')->name('index');
    #$r->any([qw/GET/]=>'/a/(:report)')->to('index#detalize')->name('detalize');
    $r->get('/a/:report',{report=>undef})->to('index#detalize')->name('detalize');
    #$r->get('/a')->to('index#up_detalize')->name('up_detalize');
    $r->post('conn51413')->to('index#contact_us')->name('contact_us');

    $r->get('/history')->to('index#history')->name('history');
    #$r->get('/vklogin')->to('index#vklogin')->name('vklogin');
    #$r->get('/contacts')->to('index#contacts')->name('contacts');
    #$r->get('/oauth2callback')->to('index#oauth2callback')->name('oauth2callback');
    $r->get('/glb')->to('index#get_liqpay_button')->name('get_liqpay_button');
    $r->post('/liqpay')->to('index#liqpay')->name('liqpay');

    $r->get('/sitemap.xml')->to('index#sitemap_xml');
    $r->get('/sitemap')->to('index#sitemap');
    $r->get('/robots.txt')->to('index#robots');
    #$r->get('/lp1')->to('index#lp1')->name('lp1'); ## ??

    ## redirect с формы API url магазина кл-сер
    ## первоочередной
    $r->get('/after_liqpay')->to('index#after_liqpay')->name('after_liqpay'); 

}

1;
