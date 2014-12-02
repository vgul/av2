#!/usr/bin/perl

use v5.10;
use DBI;
use Data::Dumper;
use strict;

## see create_site_db.sh
my $user_target = 'root';
my $password_target = '';
my $dbname_target = 'av2_kiev';
my $host_target = 'localhost';

## how many dates bold;
my $bold_dates = 1;

my $dbh_target = DBI->connect("DBI:mysql:$dbname_target:$host_target",
                                         $user_target, $password_target);
$dbh_target->do('SET NAMES utf8');

my @types = map { $_->[0] } @{ $dbh_target->selectall_arrayref('select type from av2data group by type') };

say Dumper \@types;

## 0, 1, 2
my $linear = $dbh_target->selectall_arrayref('select type, linear_name_translit, linear_name from av2data group by type, linear_name_translit' );

my $first1=1;

open FIXT, '>../m/templates/index/fixtures/kiev/data_structure.html.ep';
say FIXT '    var structure_hash = {';
foreach my $t (@types) {

    say FIXT '        '.($first1?'':',').'"'.$t.'": {';

    my @by_type = grep $_->[0] eq $t, @{ $linear };
    my $first2=1;
    foreach my $b (sort {$a->[2] cmp $b->[2] } @by_type) {
        say FIXT '            '.($first2?'':',').'"'.$b->[2].'":'.
                 ' { h: "'.$b->[1].'-'.$b->[0].'", "n": 14}';
        undef $first2;
    }

    say FIXT '        '.'}';
    undef $first1;
    #say $t, ':', scalar @by_type;
}
print FIXT '};';
close FIXT;

my @list_to_generate = map {$_->[1].'-'.$_->[0]} @{ $linear };
#say Dumper \@list_to_generate;

my @dates = map { $_->[0] } @{ $dbh_target->selectall_arrayref('select idate from av2data group by idate order by idate desc ') };
say Dumper \@dates;

my @bold_dates = @dates[0..$bold_dates-1];
say Dumper \@bold_dates;

foreach my $i ( @list_to_generate ) {
    print "$i ";
    my $h = $dbh_target->selectall_hashref( 'SELECT'.
            ' -- *, '. "\n".
            ' ad_id_start,'. "\n".
            ' hier,'. "\n".
            ' body,'. "\n".
            ' phones_to_page,'. "\n".
            ' idate '. "\n".
            " -- CONCAT(linear_name_translit,'-',type) ". "\n".
        ' FROM av2data'.  "\n".
        ' WHERE '."\n".
            ' CONCAT(linear_name_translit,"-",type) = \''. $i. "'\n".
            ' AND'. "\n".
            ' cnt=0'. "\n".
        ' -- GROUP BY ad_id_start'. "\n".
        ' -- ORDER BY hier DESC'. "\n".
        ' -- limit 2 '
        , 'ad_id_start');
    foreach my $a ( keys %{$h} ) { calculate_store_depth($h->{$a}) };
#say Dumper $h;
#exit 0;
    say scalar keys $h;
    #exit 0;
    write_fixture( data=>$h, fn=>$i );
#exit 0;
}

#####
sub calculate_store_depth {
    my $p = shift;
    my $id = $p->{ad_id_start};
    $p->{depth} = $dbh_target->selectall_arrayref(
        "select count(*) from av2data WHERE ad_id_start=$id" )->[0]->[0];
    #say Dumper $n;
}

sub write_fixture {
    my %ptr = @_;

    my $filename     = $ptr{fn}.'.html.ep';
    foreach my $demo_prod ( qw/ demo prod / ) {
        my $path = 
        '../m/templates/index/fixtures/kiev/data/'.$demo_prod;
        unless( -d $path ) {
            mkdir $path or die 'mkdir error '.$!;
        }

        open ADS, '>'.$path.'/'.$filename;

        say ADS '<div class="row row-centered">';
        say ADS '<div class="col-md-12 ">';
        say ADS '<table class="table table-condensed">';
        my $old_hier;
        foreach my $a ( 
            #sort { $ptr{data}->{$a}->{hier} cmp $ptr{data}->{$b}->{hier}   }
                                            keys %{ $ptr{data} } ) {
            my $p = $ptr{data};
            my %tmp = map {$_=>1} split /,/, $p->{$a}->{phones_to_page};
            my $phones = join '<br />', map { human_phone($_) } keys %tmp;

            #say Dumper \%tmp;
            say ADS '<tr>';
            say ADS '<td>', bold_date(
                                real=>$p->{$a}->{idate},
                                human=>date($p->{$a}->{idate})), 
                    '</td>';

            say ADS '<td>', 
                    ( $old_hier ne $p->{$a}->{hier} ?
                    '<b>'.$p->{$a}->{hier}. '</b>'. "<br />"
                    :
                    ''
                    ),

                    ( $p->{$a}->{depth} > 1 ? 
                    '<a href="#'.$p->{$a}->{ad_id_start}.'" data-group="history1" data-toggle="modal" data-target="#adhistory">'.
                          $p->{$a}->{body}.
                    '</a>' 
                    :
                          $p->{$a}->{body}
                    ).
                 '</td>';

            if( $demo_prod eq 'demo' ) {
                say ADS '<td width="15%";>', $phones, '</td>';
#<a data-toggle="tooltip" data-placement="top" title="Просмотреть" class="help_call_sc_view glyphicon glyphicon-eye-open" type="" href="#" onclick="return false;"></a>
            } else {
                say ADS '<td>', $phones, '</td>';
            }

            say ADS '</tr>';
            $old_hier = $p->{$a}->{hier};
        }
        say ADS '</table>';
        say ADS '</div><!-- col-md-12 -->';
        say ADS '</div><!-- row -->';
        close ADS;
    }
}

sub human_phone {
    my $p = shift;
    my @a = map {
        '(0'.substr($_,0,2).') '.substr($_,2,3).'-'.
                substr($_,5,2).'-'.substr($_,7);
    } split /,/, $p;
    return join ', ',@a;
}

sub date {
    my $s = shift;
    my @a = qw/янв фев мар апр май июн июл авг сен окт ноя дек /;
    my ($y,$m,$d) = split /-/, $s;
    return $d.$a[$m-1];
}

sub bold_date {
    my %p = @_; 
    if( grep $_ eq $p{real}, @bold_dates ) {
        return '<b>'.$p{human}.'</b>';
    }
    return $p{human};
}

