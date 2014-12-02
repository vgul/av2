#!/usr/bin/perl -I ../../Packages
#

use Data::Dumper;
use Encode;
use feature qw(say );
#use utf8;
use strict;
our $__db = 'a1_dnepr';
my $user = 'root';
my $password = '';
my $dbname = 'estate_dnepr';
my $host = 'localhost';
require Adata2;
use HrefTable; # qw/translate/;

    my $dbh = DBI->connect("DBI:mysql:$dbname:$host", $user, $password);
    $dbh->do('SET NAMES utf8');

    &Adata2::om2s_db_connect({city=>'dnepr'}); 
    my $__group_concat_max_len=65535;

    $Adata2::dbh->do('SET NAMES utf8');
    $Adata2::dbh->do('SET session group_concat_max_len='.$__group_concat_max_len);
  
    my $match    = translate('dnepr');
    my $match_ex = translate_ex('dnepr');
 
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
            synd.nhier = 1
        GROUP BY
            synd.synd_id, synd.nhier
    ";
    my $sth = $Adata2::dbh->prepare($query1);
    $sth->execute;

    while( my $h1 = $sth->fetchrow_hashref ) {
        my $ads = $h1->{ad_ids};
        my $query2 = "
            SELECT 
                *
                ,GROUP_CONCAT(CONCAT('0',phonen)) as phone_to_page 
            FROM
                body
            LEFT JOIN
                phones USING ( ad_id )
            WHERE
                ad_id IN ( $ads )
            GROUP BY ad_id
            ORDER BY
                idate DESC ;
        "; 
        my $sth2 = $Adata2::dbh->prepare($query2);
        $sth2->execute;
        #print Dumper $h1;
        while( my $h2 = $sth2->fetchrow_hashref ) {
            #print Dumper $h2;
            if( my $h = $match->{$h2->{hier}}  ) {
                say "Match\n", 
                "Table: $h->{table}\nRegion: $h->{region}\nTrable: $h->{trade}";
                say 'synd ', Dumper $h1;
                say 'orig ', Dumper $h2 ;
                insert_into_table(match=>$h,synd=>$h1,origin=>$h2,dbh=>$dbh);
            } else {
                unless( $h = $match_ex->{$h2->{hier}} ) {
                print 'NotMatch, ';
                say Dumper $h2 ;
                print 'NotMatch2, ', $h2->{hier}, "\n";
                }
            }
        }
        print '-'x80, "\n\n";
    }
#### End body

sub insert_into_table {
    my %data = @_;

    my %sootv = (
        change=>0,
        sale=>1,
        buy=>2,
        rent=>3,
        lease=>4
    );
    my $trade = $data{match}->{trade};
    die "Illegal type" unless grep $_ eq $trade, keys %sootv;
    my $trade_type = $sootv{ $data{match}->{trade} };
    
#say Dumper \%data;
#return;
    
    my $contact = $data{origin}->{phone_to_page};
    my ($text,@data) = split /\n/, $data{origin}->{body};
#    $contact = (grep $_ =~ m/^Тел\.:/, @data)[0];
#    $contact =~ s/^Тел\.://;
    say "Table: ", $data{match}->{table};
    say "ad_id: ", $data{origin}->{ad_id};
    say "text: ", $text;
    say "contact: ", $contact;
#    say "trade: ", $data{origin}->{trade};
#say "Error ", Dumper $data{match} unless $data{origin}->{trade};
#exit 0;

    my $q = 'INSERT INTO '.$data{match}->{table}.
            ' SET id = '. $data{origin}->{ad_id}.
            ',text = '. $data{dbh}->quote($text).
            ',phones = '. $data{dbh}->quote($contact).
            ',trade_type = '. $trade_type.
            ',created_at = '.$data{dbh}->quote($data{origin}->{idate}).
            ',sequence_id = '.($data{synd}->{ad_id_max}).
      #      ',hier = '.$data{dbh}->quote($data{origin}->{hier}).
            ',region = '. $data{dbh}->quote($data{match}->{region}).
            ( exists $data{match}->{rooms_count} ?
            ',rooms_count='. ( $data{match}->{rooms_count}?$data{dbh}->quote($data{match}->{rooms_count}) :'NULL' ) : '');

    my $sth = $data{dbh}->prepare($q);
    $sth->execute or die "Error". $q. "\n". $data{origin}->{hier};
    say $q;
}
exit 0
__END__
    my $query = "
        SELECT   
            count(*),
            synd.nhier,
            group_concat(distinct synd.hier),
            group_concat(distinct body.ad_id),
            body.body
        FROM
            synd 
        LEFT JOIN body using (ad_id)
        WHERE 
            synd.nhier<=2
        -- GROUP BY synd.synd_id
    ";

    my $sth = $Adata2::dbh->prepare($query);
    $sth->execute;

    while( my $h = $sth->fetchrow_hashref ) {
        print Dumper $h;
    }
exit 0;
__END__

    my $query = "
        select 
        s.synd_id AS sid, 
        b.hier as hier, 
        GROUP_CONCAT(DISTINCT b.hier SEPARATOR '!!!') as ahier, 
        COUNT(DISTINCT b.hier) as c, 
        COUNT(b.ad_id) as n, 
        b.*, 
        MAX(b.idate) as last_date 
    FROM 
        synd AS s
    LEFT JOIN 
        (body AS b) 
        ON  s.ad_id = b.ad_id  
    GROUP BY synd_id 
    -- HAVING n>0 \n".
     #"HAVING (c $_inParams->{h}) AND n>0 ".
     #($start_date ? "AND last_date <= '$start_date' " :' ').
     #" ORDER BY c,ahier,last_date DESC ". 
     " ORDER BY n,c,ahier,last_date DESC";

    my $sth = $Adata2::dbh->prepare($query);
    $sth->execute;

    while( my $h = $sth->fetchrow_hashref ) {
        print $h->{n}, ' ', $h->{sid}, ' ', #decode('utf8',$h->{body})
                    $h->{body}
       ; 
        print "\n";
    }

exit 0;

__END__

if(0) {
my  $_freq_sth =  $Adata2::dbh->prepare(
"SELECT s.synd_id AS synd_id, body.*
      , p.phonen, p.phones
    FROM synd AS s 
   LEFT JOIN  (
     body 
    , phones AS p
   ) ON    s.ad_id = body.ad_id 
      AND s.ad_id = p.ad_id 
    WHERE s.synd_id=? AND body.idate <= ? AND body.idate >= ?
    ORDER BY body.hier" );

  $Adata2::dbh->do('SET NAMES utf8');
  $Adata3::dbh->do('SET session group_concat_max_len='.$__group_concat_max_len);

  $_freq_sth->bind_param( 1, $synd_id );
  $_freq_sth->bind_param( 2, $start_date );
  $_freq_sth->bind_param( 3, $end_date );
  $_freq_sth->execute;
}
