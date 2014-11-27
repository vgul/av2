package Captcha::Index;
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;


sub captcha {
    my $self = shift;
    $self->render( data => $self->create_captcha, format=>'jpg' );
                       #$self->render( text => 'hi' );
}

sub some_post {
    my ($self, $c) = @_;
    if ($self->validate_captcha($c->req->param('captcha'))){
                       } else {
    }
}

sub index {
}

1;
