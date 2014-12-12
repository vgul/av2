#!/usr/bin/perl

use v5.10;
use DBI;
use Data::Dumper;
use File::Path;
use Getopt::Long;
use Cwd 'abs_path';
use File::Basename;
#use K116::Config;
use strict;

my $my_absolute_path1 = abs_path($0);
my $my_absolute_path = dirname( $my_absolute_path1 );
#my $my_script_name = basename( $my_absolute_path1 );

#say "Cwd:\n", $my_absolute_path1 , "\n",
#$my_absolute_path, "\n",
#$my_script_name;
#say "0: ", $0;

#my ($subject,$from,$message);
GetOptions(#"s=s" => \$subject,
           #"f=s" => \$from
);

if( @ARGV != 1 or ( $ARGV[0] ne 'kiev' and $ARGV[0] ne 'dnepr' and $ARGV[0] ne 'odessa' ) ) {
    say "You need to specify 'kiev|dnepr|odessa'";
    exit 0;
}
my $region = $ARGV[0];

## see create_site_db.sh
my $user_target = 'root';
my $password_target = '';
my $dbname_target = "aviso2";
my $host_target = 'localhost';

## how many dates bold;
my %_bold_dates = ( kiev=>2, dnepr=>1, odessa=>1 );
my $bold_dates = $_bold_dates{$region};
say 'Bold dates: ', $bold_dates;
die "Not 1 or 2 for bold dates" if $bold_dates !=1 and $bold_dates !=2 ;

my $dbh_target = DBI->connect("DBI:mysql:$dbname_target:$host_target",
                                         $user_target, $password_target);
$dbh_target->do('SET NAMES utf8');
$dbh_target->do('SET session group_concat_max_len=65535');

#my (%deal, %obj, $fquery, $sth_freq);
#BEGIN { 
my %deal = ( 'kup'=>'Куплю','pro'=>'Продам','sda'=>'Сдам','sni'=>'Сниму'  );
my %obj = ( 'kv'=>'Квартиры','do'=>'Дома','uc'=>'Участки','of'=>'Офисы','ko'=>'Коммерч.' );
    
#};
my $sth_freq=$dbh_target->prepare(
    "select count(*) from ${region} WHERE ad_id_start=?" ); #->[0]->[0];


my $linear = $dbh_target->selectall_arrayref(
    'SELECT '.
        'type,                        '. "\n". # 0
        'linear_name_translit,        '. "\n". # 1
        'linear_name,                 '. "\n". # 2
        'group_concat(distinct idate),'. "\n". # 3
        'count(distinct hier),        '. "\n". # 4
        'group_concat(distinct hier SEPARATOR \'|\' ) '. "\n". # 5
    'FROM '. $region . "\n".
    'GROUP by type, linear_name_translit' );
    

my $hash={};
my @dates=();
my @names_of_html_reports=();
foreach my $l ( @{$linear} ) {
    store_dates( \@dates,  $l->[3]);
    push @names_of_html_reports, $l->[1].'-'.$l->[0];
    $hash->{$l->[0]}->{cnt}++;
    $hash->{$l->[0]}->{arr}->{$l->[1]}->{name} = $l->[2];
    $hash->{$l->[0]}->{arr}->{$l->[1]}->{n}    = $l->[4];
    push @{$hash->{$l->[0]}->{arr}->{$l->[1]}->{single}}, 
            map { {h=>$_,n=>calculate_ads_num($_) } } split /\|/, $l->[5];
}
#say Dumper @names_of_html_reports;
write_sitemap_xml( \@names_of_html_reports );
#say Dumper \@dates;
#say Dumper $hash;

@dates = reverse sort @dates;
my @bold_dates = @dates[0..$bold_dates-1];
say 'bold_dates: ', Dumper \@bold_dates;
write_files( $hash );



exit 0;

##########################################
##########################################
sub calculate_ads_num {
    my $h = shift;
    return $dbh_target->selectall_arrayref(
        "select count(*) from ${region} WHERE hier=". 
            $dbh_target->quote( $h ) )->[0]->[0];
}

sub write_fixture {
    my $p = shift;
    #say '****', Dumper $p;
    my $uniq = $p->{name_eng}.'-'.$p->{index};
    my $desc_path = $my_absolute_path.'/../m/templates/index/fixtures/'.
                    $region.'/data/descriptions/';
    mkpath( $desc_path );
    
    my $desc_full = ${desc_path}.$uniq.'.html.ep';

    open DESC, ">$desc_full";
    my $meta = 'Недвижимость <%= $self->Region_cyr %>'.' '.$p->{index_cyr}. '. '.
                ( $p->{inner}->{name} ne $p->{index_cyr} ? $p->{inner}->{name} : '').
                ' Без комиссии. Без посредников.';
    print DESC $meta;
    #print $meta;
    close DESC;

    
    my $h = $dbh_target->selectall_hashref( 'SELECT'.
            ' -- *, '. "\n".
            ' ad_id_start,'. "\n".
            ' hier,'. "\n".
            ' body,'. "\n".
            ' phones_to_page,'. "\n".
            ' idate '. "\n".
            " -- CONCAT(linear_name_translit,'-',type) ". "\n".
        ' FROM '.${region}. "\n".
        ' WHERE '."\n".
            ' CONCAT(linear_name_translit,"-",type) = \''. $uniq. "'\n".
            ' AND'. "\n".
            ' cnt=0'. "\n".
        ' -- GROUP BY ad_id_start'. "\n".
        ' -- ORDER BY hier DESC'. "\n".
        ' -- limit 2 '
        , 'ad_id_start');

    foreach my $demo_prod ( qw/ demo prod / ) {
        my $ads_path = $my_absolute_path.'/../m/templates/index/fixtures/'.$region.
                '/data/'.$demo_prod;
        mkpath $ads_path;
        my $ads_file = $ads_path.'/'.$uniq.'.html.ep';
        #say "***** $ads_file";
        open ADS, ">$ads_file";

        say ADS '<h3 style="margin-top: 1px;">', $p->{index_cyr}, '. ',
                ( $p->{inner}->{name} ne $p->{index_cyr} ? $p->{inner}->{name} : ''),
                '</h3>';

        my $menu = sub {
            say ADS '<div class="panel panel-default">';
            say ADS '    <div class="panel-body" style="text-align: left;">';
            say ADS '<a href="<%= url_for "index" %>">'.'Главное меню'.'</a><br />';
            say ADS '<a id="'.$p->{index}.'" href="#">Выбор по разделу'.
                    '</a><br />' if $p->{cnt};
            #say ADS '<pre>';
            #say ADS Dumper $p;
            #say ADS '</pre>';
            #say ADS '<a id="subscribe" href="#">Подписаться на обновления</a><br />';
            say ADS '    </div>';
            say ADS '</div>';
        };

        &$menu();

        say ADS '<div class="row row-centered">';
        say ADS '<div class="col-md-12 ">';
        say ADS '<table class="table table-condensed table-condensed-detalize" ';
        my $old_hier;
        my $first=1;
        foreach my $a ( keys %{ $h } ) {

            my %tmp = map {$_=>1} split /,/, $h->{$a}->{phones_to_page};
            my $phones = join '<br />', map { human_phone($_) } keys %tmp;

            my $depth = calculate_ad_depth( $a );
            say ADS '<tr>';
            say ADS '<td'.($first?' class="detalize-top"':'').'>', 
                        bold_date(
                                real=>$h->{$a}->{idate},
                                human=>date($h->{$a}->{idate})), 
                     '</td>';
            say ADS '<td'.($first?' class="detalize-top"':'').'>', 
                    ( $old_hier ne $h->{$a}->{hier} ?
                    '<b>'.$h->{$a}->{hier}. '</b>'. "<br />"
                    :
                    ''
                    ),

                    ( ${depth} > 1 ? 
                    '<a href="#'.$h->{$a}->{ad_id_start}.'"'.
                    ' data-toggle="modal" '.
                    (
                        (grep $_ eq $h->{$a}->{idate}, @bold_dates) ?
                        'data-bold="1" '
                        :
                        ''
                    ).
                    'data-target="#adhistory">'.
                          $h->{$a}->{body}.
                    '</a>' 
                    :
                          $h->{$a}->{body}
                    ).
                 '</td>';

            if( $demo_prod eq 'demo' ) {
                ## TODO green phones on prod
                if( grep $h->{$a}->{idate} eq $_, @bold_dates ) {
                    say ADS '<td'.($first?' class="detalize-top"':'').'>', 
                        '<a data-toggle="modal" '.
                          ' data-target="#ppay" '.
                          ' title="Смотреть" '.
                          ' class="glyphicon glyphicon-eye-open" '.
                          ' href="#'.$h->{$a}->{ad_id_start}.'"'.
                         #' onclick="return false;"'.
                          '></a>',
                        '</td>';
                } else {
                    say ADS '<td'.($first?' class="detalize-top"':''),
                    ' width="15%">', 
                    $phones, '</td>';
                }
            } else {
                if( grep $h->{$a}->{idate} eq $_, @bold_dates ) {
                    say ADS '<td'.($first?' class="detalize-top"':''),
                    ' width="15%">', 
                    '<b><font color="green">', 
                                        $phones, '</font></b></td>';
                } else {
                    say ADS '<td'.($first?' class="detalize-top"':''),
                    ' width="15%";>', $phones, '</td>';
                }
            }

            say ADS '<tr>';
            $old_hier = $h->{$a}->{hier};
            undef $first;
        }
        say ADS '</table>';
        say ADS '</div><!-- col-md-12 -->';
        say ADS '</div><!-- row -->';

        &$menu();

        #say Dumper $p;
        say ADS '<div style="display: none;">';
        #say ADS '<div style="display: show;">';
        say ADS '<h2>',
                '<%= $self->Region_cyr %>', ' ',
                $p->{index_cyr}, '. ',
                ( $p->{inner}->{name} ne $p->{index_cyr} ? $p->{inner}->{name} : ''),
                '</h2>';
        say ADS '<a href="<%= url_for "sitemap" %>">Карта сайта</a>';
        foreach my $d ( @{ $p->{inner}->{single} } ) {
            say ADS '<h3>',
                '<%= $self->Region_cyr %>', ' ',
                $d->{h},
                '</h3>';
        }
        say ADS '</div>';


        say ADS '<p align="right">',
                'Информация собирается из интернета и анализируется на предмет 1х рук автоматически, поэтому возможен незначительный процент неточностей.',
                '</p>';
        close ADS0;
    }
}

sub write_files {
    my $hash = shift;
    my $path = $my_absolute_path.'/../m/templates/index/fixtures/'.$region;
    mkpath( $path );

    open BEG1, ">${path}".'/start1.html.ep';
    open JS_S, ">${path}".'/data_structure.html.ep';
    open MAP,  ">${path}".'/sitemap.html.ep';

    say BEG1 '<div class="row row-centered">';
    say JS_S '   var structure_hash = {';
    say MAP '   '. '<ul>'; #<div class="panel-body" style="text-align: center;">
    my $first=1;
    my $first_js=1;

    foreach my $obj ( qw/kv do uc of ko/ ) {
        say BEG1 '<div class="col-md-2', ($first?' col-md-offset-1':''), '">';
        say BEG1 '    '.'<ul>';

        foreach my $deal ( qw/ kup pro sda sni / ) {
            my $index = "${obj}_${deal}";
            my $index_cyr = $obj{$obj}.' '.$deal{$deal};

            #say "generatate $hash->{$index}";
            ## start1.html.ep
            if( exists $hash->{$index} ) {
                my $li = '    '.'<li>';
                if( $hash->{$index}->{cnt} > 1 ) {
                    #$index_cyr .= '_'.$hash->{$index}->{cnt};
                    $li .= '<a id="'.${index}.'" href="#'
                } else {
                    my $html_file = (keys %{$hash->{$index}->{arr}})[0];
                    $li .= '<a href="<%=    $self->url_for("detalize") %>'.
                           $html_file.'-'.$index.'.html';
                           #$hash->{$index}->{arr}->{$k}->{name}.'.html';
                }
                $li .= '">'.$index_cyr.
                       '</a></li>';
                say BEG1 $li;


                ## JS_S
                ## MAP
                if( $hash->{$index}->{cnt} > 1 ) {
                    say JS_S '       '.
                            ($first_js?'':',').
                            '"'.$index.'": {';

                    say MAP '        <li>'.$index_cyr.'</li>';

                    my $first0=1;
                    say MAP '        <ul><!-- level2 -->';
                    foreach my $i ( 
                                    sort {
                                        $hash->{$index}->{arr}->{$a}->{name}
                                        cmp
                                        $hash->{$index}->{arr}->{$b}->{name}
                                    }
                                    keys %{ $hash->{$index}->{arr} } ) {

                        say JS_S '           '.
                            ($first0?'':',').
                            '"'.
                            $hash->{$index}->{arr}->{$i}->{name}.
                            '": { "h": "'. $i .'-'.$index.'", "n": "'.
                            $hash->{$index}->{arr}->{$i}->{n}.
                            '" }';
                        undef $first0;

                        say MAP '            '.
                                '<li>'.
                                '<a href="<%= url_for "detalize" %>'.$i.'-'.$index.
                                '.html'.'">'.
                                $hash->{$index}->{arr}->{$i}->{name}.
                                '</a>'.
                                '</li>';
                        say MAP '            <ul> <!-- level 3 -->';
                        foreach my $j ( 
                                    # sort
                                    @{$hash->{$index}->{arr}->{$i}->{single}} ) {
                            say MAP '                '.'<li>'.
                                $j->{h}. 
                                '  ['. $j->{n}. ']';
                        }

                        say MAP '            </ul>';


                    write_fixture( { inner=>$hash->{$index}->{arr}->{$i},
                                     name_eng=>$i, 
                                     index_cyr=>$index_cyr,
                                     index=>$index,
                                     cnt=>$hash->{$index}->{cnt} } );
                    }
                    say MAP '        </ul>';
                    say JS_S '       }';
                    undef $first_js;


                } else {
                    my $k = (keys %{ $hash->{$index}->{arr} })[0];
                    my $href = $k.'-'.$index.'.html';
                    write_fixture( { inner=>$hash->{$index}->{arr}->{$k},
                                     name_eng=>$k, 
                                     index_cyr=>$index_cyr,
                                     index=>$index } );


                    say MAP '        <li>'.
                            '<a href="<%= url_for "detalize" %>'.$href.'">'.
                             $index_cyr.' : '.$k.'-'.$index.'</a>'.
                            '</li>';
                }


            } else {
                say BEG1 '      '.'<li>'.$index_cyr.' *</li>';
                say MAP '   <li>'.$index_cyr.' *</li>';
            }

        }
say MAP;
say MAP '        <hr />';
say MAP;
        say BEG1 '   '.'</ul>';
        say BEG1 '</div>'; # <!-- col-md-2',($first?' col-md-offset-1':''), ' -->';
        undef $first;
    }
    say MAP '   </ul>';
    say BEG1 '</div> <!-- row row-centered -->';
    say JS_S '   };';
    close BEG1;
    close JS_S;
    close MAP;
}


sub store_dates {
    my $a = shift;
    my $s = shift;
    foreach my $e (split /,/, $s) {
        push @{ $a }, $e unless grep $_ eq $e, @{ $a };
    }
}

sub write_sitemap_xml {
    my $hrefs = shift;
    my $sitemapfile_path = $my_absolute_path.'/../m/templates/index/fixtures/'.$region;
    my $sitemapfile = ${sitemapfile_path}.'/sitemap.xml.html.ep';
    mkpath $sitemapfile_path;
    open XML, ">${sitemapfile}" or die "Error open file $!";
    say XML '<?xml version="1.0" encoding="UTF-8"?>';
    say XML '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">';
    foreach my $file ( @{ $hrefs } ) {
        say XML '<url>';
        say XML '  <loc><%= $self->req->url->base %>'.
                        '<%= $self->url_for(\'detalize\') %>'.$file.'.html</loc>';

        my $lastmod = `date +'%FT%T+00:00'`; chomp $lastmod;
        say XML '  <lastmod>'.$lastmod.'</lastmod>';
        say XML '  <changefreq>daily</changefreq>';
        say XML '  </url>';
    }
    say XML '</urlset>';
    close XML;
    #my $sitemapfile='../m/templates/index/fixtures/'.$region.'/data/'.$demo_prod;
}

sub calculate_ad_depth {
    my $ad_id = shift;
    $sth_freq->bind_param( 1, $ad_id );
    $sth_freq->execute or die "sth err $!";
    return $sth_freq->fetchrow_array. ' **';
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
        return '<b><font color="green">'.$p{human}.'</font></b>';
    }
    return $p{human};
}

