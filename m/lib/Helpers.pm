package Helpers;
use v5.10;
use Data::Dumper;
use Encode;
use strict;

sub index_subtext {
    my $self = shift;
    return $self->config->{$self->region}->{index_subtext};
    #'Один раз в неделю.'
}

sub Region_cyr {
    my $self = shift;
    return $self->config->{$self->region}->{name};
}

sub Region_cyr_short {
    my $self = shift;
    return $self->config->{$self->region}->{name_short} if 
        exists $self->config->{$self->region}->{name_short};;
    return $self->config->{$self->region}->{name};
    
}

my @month = qw/янв фев мар апр май июн июл авг сен окт ноя дек /;
sub human_date {
    my $self = shift;
    my $date = shift;
    my ($y,$m,$d) = split /-/, $date;
    return decode('utf8',$d.$month[$m-1]);
}

sub bold_dates {
    my $self = shift;
    return $self->config->{$self->region}->{bold_dates};
}

sub amount {
    my $self = shift;
    return $self->config->{$self->region}->{amount};
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
    my $host = $self->req->url->base->host;
    foreach my $r ( qw/kiev dnepr odessa/ ) {
        my $re = $self->config->{$r}->{match};
        if( $host =~ m/$re/ ) {
            return $r;
        }
    }
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

sub dates_info {
    my $self = shift;
    my $dates_file = shift;

    #my @info_dates; 
    open DATES, $dates_file or die "dates file: $dates_file";
    my @info_dates = map { chop; $_ } <DATES>;
    close DATES;

    #say "BD: ", $self->bold_dates, ':', Dumper \@info_dates;

    my $free_selected_until = join '.', reverse split /-/, $info_dates[$self->bold_dates - 1];

    my $next_update = next_update( \@info_dates );

    if( $next_update == 1 ) {
        $next_update = '1 день';
    } elsif( grep $next_update == $_, qw/2 3 4/ ) {
        $next_update = $next_update.' дня';
    } else {
        $next_update = $next_update.' дней';
    }

    my $permitted_days = int($self->config->{$self->region}->{prod_age}/
            (60*60*24));

    if( $permitted_days == 1 ) {
        $permitted_days = '1 дня';
    } else {
        $permitted_days = $permitted_days.' дней';
    }



    #    my( $free_selected_until,
    #        $next_update,
    #        $permitted_days ) =
    return 
           $free_selected_until,
           decode('utf8',$next_update),
           decode('utf8',$permitted_days);
 
}

sub next_update {
    my $data = shift;

    #say Dumper \@a;

    my %statistics;
    foreach my $d (@$data ) {
        my $week = `date -d "$d" +%u`;
        chomp $week;
        #say "$d : $week";
        $statistics{$week} =1;
    }
    #say Dumper \%statistics;
    #
    my $today = `date +'%F %u'`;
    chomp $today;

    my $next_date;
    my $shift;
    for( my $i=0; $i<10; $i++ ) {
        my $d = `date -d '$i day' +'%F %u'`;
        chomp $d;
        next if $today eq $d;
        #say $d;
        my( $date, $week ) = split /\s+/, $d;
        if( exists $statistics{$week} ) {
            $next_date = $date;
            $shift = $i-0;
            last;
        }
    }
    return $shift;
    #say "I:$shift";
}
1;

