
use v5.10;
use Data::Dumper;
use strict;


my %loc = (
    super => {
                aa=>'bb',
                cc=>'dd'
    }
    ,nested1=>{ 
                kk=>'vv'
                ,ndata1=>'NEW ndata1'
                ,ndata2=> [ 18, 111 ]
                 }
    ,val14 => '11'
);

my $here = {
    nested1 => {
        ndata1=>'value_nd1',
        ndata2=>'value_nd2'
    }
};

say Dumper \%loc, $here;

cross_hash( $here, \%loc);

say 'Final: ', Dumper $here;
sub cross_hash() {
    my $origin = shift;
    my $to_add = shift;
    my @origin_keys;
    foreach my $k ( keys %$origin ) {
        push @origin_keys, $k;
        if( exists $to_add->{$k} ) {
            if( ref $origin->{$k} eq 'HASH' ) {
                cross_hash( $origin->{$k}, $to_add->{$k} );
            } else {
                $origin->{$k} = $to_add->{$k};
            }
        } 
    }

    foreach my $k ( keys %{ $to_add } ) {
        next if grep $k eq $_, @origin_keys;
        $origin->{$k} = $to_add->{$k};
    }
}

