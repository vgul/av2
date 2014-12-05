package Helpers;
use v5.10;
use Data::Dumper;
use Encode;

sub index_subtext {
    my $self = shift;
    return $self->config->{$self->region}->{index_subtext};
    #'Один раз в неделю.'
}

my @month = qw/янв фев мар апр май июн июл авг сен окт ноя дек /;
sub human_date {
    my $self = shift;
    my $date = shift;
    my ($y,$m,$d) = split /-/, $date;
    return decode('utf8',$d.$month[$m-1]);
}

sub sandbox_payment {
    my $self = shift;
    return $self->config->{$self->region}->{sandbox_payment};
}

sub is_demo {
    my $self = shift;
    return 1 unless $self->session('p');
    return 1 if     ref $self->session('p') ne 'HASH';
    my $last_pay = (reverse sort keys %{ $self->session('p') })[0];
    return 0 if time - $last_pay <= $self->config->{$self->region}->{'prod_age'};
    return 1;
}

sub is_prod {
    my $self = shift;
    return 0 unless $self->session('p');
    return 0 if     ref $self->session('p') ne 'HASH';
    my $last_pay = (reverse sort keys %{ $self->session('p') })[0];
    return 1 if time - $last_pay <= $self->config->{$self->region}->{'prod_age'};
    return 0;
}

sub region {
    my $self = shift;
    return 'kiev';
}

sub how_old_prod {
    ## JUST calculate diff
    my $self      = shift;
    my $pay_sheet = $self->session('p');
    my @stampes   = reverse sort keys %{ $pay_sheet };
    my $age       = time - $stampes[0];
    return $age;
}
sub conf_prod_age {
    my $self      = shift;
    return $self->config->{$self->region}->{prod_age};
}

#sub show_p {
#    my $self = shift;
#    $self->debug( Dumper $self->session('p') );
#}

1;

