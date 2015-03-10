package Av::Test;
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;

use strict;

sub test {
    my $self = shift;

my $sess_debug;

$sess_debug = '           '. time. "\n";
$sess_debug .= Dumper $self->session; #('p');
$sess_debug .= '<hr/>';
my $conf = $self->conf_prod_age;
my $curr = $self->how_old_prod;
$sess_debug .= 'Conf prod_age:'. $self->conf_prod_age. " as constant\n";
$sess_debug .= 'How old prod: '. $self->how_old_prod. " calculate from cur time\n";
$sess_debug .= 'diff:         '. ($conf - $curr). " REST ". ($conf-$curr)/60 ."\n";
$sess_debug .= 'is_prod: '. $self->is_prod. "\n";
$sess_debug .= 'is_demo: '. $self->is_demo. "\n";


$self->session('here'=>'here2');

    $self->render( text=>
"<pre>".
"here2\n".

$sess_debug

 );

}
1;
