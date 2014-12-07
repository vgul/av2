#!/usr/bin/perl

use v5.10;
use DBI;
use YAML;
use Encode;
use Text::Unidecode;
use Data::Dumper;
use Data::Printer;
use Getopt::Long;
use File::Path;
use K116::Config;
require 'HumanHier.pl';
use strict;
$|=1;

#my ($subject,$from,$message);
GetOptions(#"s=s" => \$subject,
           #"f=s" => \$from
);

if( @ARGV != 1 or ( $ARGV[0] ne 'kiev' and $ARGV[0] ne 'dnepr' and $ARGV[0] ne 'odessa' ) ) {
    say "You need to specify 'kiev|dnepr|odessa'";
    exit 0;
}
my $region = $ARGV[0];
my $dbname_source="a1_${region}";
my $apoint = K116::Config->new('aviso-sources');
my @source_dsn = $apoint->dsn("a1_$region");

## see create_site_db.sh
my $user_target = 'root';
my $password_target = '';
my $dbname_target = "av2_${region}_pre";
my $host_target = 'localhost';

my $structure = YAML::LoadFile("Yamles/$region.yaml");
my $linear_structure = linear( $structure );

sub linear {

    my $s = shift;
    my %types1_eng = (
        'Куплю'    => 'kup',
        'Продам'   => 'pro',
        'Сдам'     => 'sda',
        'Сниму'    => 'sni'
    );
    my %types2_eng = (
        'Квартиры' => 'kv',
        'Дома'     => 'do',
        'Участки'  => 'uc',
        'Офисы'    => 'of',
        'Коммерч.' => 'ko'
    );

    my @types2 = map { encode('utf8', $_ ) } @{ $s->{rows} };
    #say Dumper @types; 
   
    my $final = {}; 
    for( my $i=0; $i < scalar @{ $s->{body}}; $i++ ) {
        my $h1 = $s->{body}->[$i];
        my $type = (keys %{$h1})[0];
        say $i, ' ', encode('utf8',$type), ':', $h1->{$type}, ':', $types1_eng{encode('utf8',$type)};
        for( my $j=0; $j< scalar @{ $h1->{$type} }; $j++ ) {
            #say $types2[$j], $types2_eng{$types2[$j]};
            my $type2db =  $types2_eng{$types2[$j]} .'_'. $types1_eng{encode('utf8',$type)};
            my $type_human =  $types2[$j] .' '. encode('utf8',$type);
            print "\t", $j, ':', $type2db;

            my $item = $h1->{$type}->[$j];
            my $ref0 = ref $item;
            unless( 0 || $ref0 ) {
                print ' ', encode('utf8', $item );
                my $k0 = encode('utf8',$item);
                $k0 =~ s/\\\\/\\/g;
                $final->{$k0} = { type=>$type2db, type_human=>$type_human };
            } elsif( 1 && $ref0 eq 'ARRAY' ) {
                foreach my $a ( @{$item} ) {
                    my $k = (keys %{$a})[0];
                    print "\n\t\t", ref $a, ' ', encode('utf8',$k), ' || ',
                                encode('utf8',$a->{$k});
                    my $k0 = encode('utf8',$a->{$k});
                    $k0 =~ s/\\\\/\\/g;
                    $final->{$k0} = 
                        { type=>$type2db, name=>encode('utf8',$k), 
                                type_human => $type_human };
                }
            } elsif( $ref0 eq 'HASH' ) {
                my $k = (keys %{$item})[0];
                print " **Hash ",  encode('utf8',$k), ' || ', encode('utf8',$item->{$k});
                my $tmp = {type=>$type2db};
                if( $k eq 'none' ) {
                    #$tmp->{name} = encode('utf8',$k);
                    $tmp->{none} = 1;
                    $tmp->{type_human} = $type_human;
                } else {
                    $tmp = { type=> $type2db, type_human=>$type_human };
                }
                my $k0 = encode('utf8',$item->{$k});
                $k0 =~ s/\\\\/\\/g;
                $final->{$k0} = $tmp;
            } else {
                die 'Abnormal ref ';
            }
            say;
        }

        #say 'here: ', p $h1->{$type};
        #say Dumper $i; #, $types_eng{$i};
    }
#    say p $final;
#    say '-'x40;
#    say Dumper $final;
#exit 0;
    return $final;
}

say p $linear_structure;

## в исходном - по два слеша
#my @re_rubrics = map { s/\\\\/\\/g; $_ } keys %{$linear_structure};
my @re_rubrics =                          keys %{$linear_structure};
say p @re_rubrics;
#exit 0;


my $__group_concat_max_len=65535;
my $dbh_source = DBI->connect(@source_dsn);

$dbh_source->do('SET NAMES utf8');
$dbh_source->do('SET session group_concat_max_len='.$__group_concat_max_len);

my $dbh_target = DBI->connect("DBI:mysql:$dbname_target:$host_target",
                                         $user_target, $password_target);
$dbh_target->do('SET NAMES utf8');


    ## Declaration
    my $final_data 
#                  = { 
#                       do_kup=> [ {} ]
#                       do_sda=> [ {} ]
#                    }
                ;

    my $query1 = "
        SELECT
            count(*) ad_n,
            group_concat(distinct synd_id),
            group_concat(distinct ad_id) as ad_ids,
            synd.synd_id,
            MAX(synd.ad_id) as ad_id_max,
            synd.nhier
        FROM
            synd
        WHERE
            synd.nhier IN (1)
        -- AND  test case}
        --    ad_id = '2987799'
        GROUP BY
            synd.synd_id, synd.nhier
 -- limit 50;
    ";
    my $sth_source1 = $dbh_source->prepare( $query1 );
    $sth_source1->execute;

    my $num_records;
    while( my $h1 = $sth_source1->fetchrow_hashref ) {
        my $ads = $h1->{ad_ids};
        my $query2 = "
            SELECT 
                *
                ,GROUP_CONCAT(distinct phonen) as phones_to_page 
            FROM
                body
            LEFT JOIN
                phones USING ( ad_id )
            WHERE
                ad_id IN ( $ads )
                -- AND -- looking for test variant
                --  body regexp '8330966'
            GROUP BY ad_id
            ORDER BY
                idate DESC ;
        "; 
        my $sth_source2 = $dbh_source->prepare($query2);
        $sth_source2->execute;

        my @tmp_data;
        while( my $h2 = $sth_source2->fetchrow_hashref ) {
#say Dumper $h2;
#next;
            my $hier0 = _humanHier( $h2->{hier} ); 
            my @rubrics0 = grep $hier0 =~ m/$_/, @re_rubrics;
            if( scalar @rubrics0 > 1 )  {
                say "Hier0: $hier0";
                say Dumper \@rubrics0;
                die 'Abnormal matchning ' 
            }
            if( @rubrics0 ) {
#                say '*** ', $linear_structure->{$rubrics0[0]}->{type},' ', $hier0;
                my ($body,$bottom) = split /\n/, $h2->{body}, 2;
#                say $body;
                $h2->{hier} = $hier0;
                $h2->{body} = $body;
                $h2->{rubrics0}   =$rubrics0[0];
                $h2->{type}       =$linear_structure->{$rubrics0[0]}->{type};
                $h2->{type_human} =$linear_structure->{$rubrics0[0]}->{type_human};
                $h2->{none}       =$linear_structure->{$rubrics0[0]}->{none};

                my $linear_name;
                $linear_name = $linear_structure->{$rubrics0[0]}->{name} 
                        if exists $linear_structure->{$rubrics0[0]}->{name};
                $linear_name = $h2->{type_human} unless $linear_name;

                $h2->{linear_name} = $linear_name;
                my $translit = unidecode(decode('utf8',$linear_name));
                $translit =~ s/\W+/_/g;

                $h2->{linear_name_translit} = $translit;

#say 'pushed ' . $h2->{body};
                push @tmp_data, $h2;
            }
            next; 
        }
        if( @tmp_data ) {
  #      #print Dumper \@tmp_data
            make_records(source_data=>\@tmp_data);
            $num_records++; 
            unless( $num_records % 50 ) {
                print scalar( @tmp_data).'['.($num_records).'],';
            }
        }
    }

    say Dumper $final_data;

    #write_fixture( $final_data );
## END


## subs
sub write_fixture {
    my $stru = shift;
    my $path = "../templates/index/fixtures/${region}";
    mkpath( $path );
    open FIXT, ">${path}/data_structure.html.ep";
    say FIXT '    var structure_hash = {';
    my $first1=1;
    foreach my $t1 ( keys %{ $stru } ) {
        say FIXT '        '.($first1?' ':','). "${t1}: {";
        my @t2lines = sort keys %{ $stru->{$t1} };
        my $first2 =1;
        foreach my $t2 ( @t2lines ) {
            say FIXT '            '.($first2?' ':','). 
                "\"${t2}\": {h:\"". $stru->{$t1}->{$t2}."\"}";
            undef $first2;
        }
        say FIXT '        '.'}';
        undef $first1;
    }
    print FIXT '};';
    close FIXT;
}

sub make_records() {
    my %data = @_;

    my %ph1 = map { $_->{phones_to_page}=>1 } @{ $data{source_data} };
    my $ph = join ',', keys %ph1;
    my %tmp = map {$_=>1} split /,/, $ph;
    $ph = join ',', keys %tmp;

    my $cnt =0;
    my $ad_id_start;
    foreach my $a ( sort {$b->{idate} cmp $a->{idate} } @{ $data{source_data}} ) {
        my $linear_none;
        $linear_none = $linear_structure->{$a->{rubrics0}}->{none} 
                    if exists $linear_structure->{$a->{rubrics0}}->{none};
        die 'None ' if $linear_none;

        unless( $cnt ) { $ad_id_start = $a->{ad_id}; }

        $final_data->{$a->{type}}->{$a->{linear_name}} = $a->{hier_translit};
        insert_to_target_db(data=>$a, cnt=>$cnt++, ad_id_start=>$ad_id_start);
    }
#exit 0;

#    say  $query, ' ** ', $hier;
}

sub insert_to_target_db() {
    my %p = @_;
    my $a = $p{data};
    my $cnt = $p{cnt};
    my $ad_id_start = $p{ad_id_start};

#say Dumper $a;
    my $query = 'INSERT INTO av2data SET '."\n".
        'ad_id='. $a->{ad_id}."\n".
        ',cnt='. $cnt . "\n".
        ',ad_id_start='. $ad_id_start ."\n".
        ',body='. $dbh_target->quote($a->{body}). "\n".
        ($cnt == 0 ?
        ',phones_to_page=\''. $a->{phones_to_page}. '\''. "\n" 
        
        : ''
        ).
        ',hier=\''. $a->{hier}. '\''. "\n".
        ',linear_name_translit=\''. $a->{linear_name_translit}. '\''. "\n".
        ',linear_name='. $dbh_target->quote($a->{linear_name}). "\n".
        ',idate=\''. $a->{idate} . '\''. "\n".
        ',icnum='. $a->{icnum} . ''. "\n".
        ',type=\''.  $a->{type} . '\''. "\n".
        ',num='.   $a->{num} . ''. "\n".
        ',page='.  $a->{page} . ''. "\n".
    '';

    #say $query;
#return;
    my $sth = $dbh_target->prepare( decode('utf8',$query) ) or die $dbh_target->errstr;
    $sth->execute;
    #my $rv = $dbh_target->last_insert_id(undef, undef, undef, undef);
    #say "RV: $rv";

}

