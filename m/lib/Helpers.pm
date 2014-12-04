package Helpers;
use Data::Dumper;

sub is_demo {
    my $self = shift;
    my $last_pay = (reverse sort keys %{ $self->session('p') })[0];
    return 0 if time - $last_pay <= $self->config('how_old_prod');
    return 1;
}

sub is_prod {
    my $self = shift;
    my $last_pay = (reverse sort keys %{ $self->session('p') })[0];
    return 1 if time - $last_pay <= $self->config('how_old_prod');
    return 0;
}

sub region {
    my $self = shift;
    return 'kiev';
}

sub how_old_prod {
    my $self = shift;

    my $pay_sheet = $self->session('p');
    my @stampes = reverse sort keys %{ $pay_sheet };
    my $age = time - $stampes[0];
    $self->debug( "how_old_prod: $age" );
    return $age;
}

sub show_p {
    my $self = shift;
    $self->debug( Dumper $self->session('p') );
}

1;

