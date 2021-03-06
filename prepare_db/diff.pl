#!/usr/bin/perl

use v5.10;
use Data::Dumper;
use Data::Printer;
use String::Diff;
use Encode;
use strict;
my @a = (
 'Днепропетровск Коммерческая недвижимость. Аренда Торговые помещения -> Дн-ск. Кировский р-н'
,'Днепропетровск Коммерческая недвижимость. Аренда Складские помещения -> Дн-ск. Красногвардейский р-н'
,'Днепропетровск Коммерческая недвижимость. Аренда Объекты сферы обслуживания -> Дн-ск. Жовтневый р-н'
,'Днепропетровск Коммерческая недвижимость. Аренда Объекты сферы обслуживания -> Дн-ск. Бабушкинский р-н'
,'Днепропетровск Коммерческая недвижимость. Аренда Торговые помещения -> Дн-ск. Бабушкинский р-н'
,'Днепропетровск Коммерческая недвижимость. Аренда Складские помещения -> Дн-ск. Бабушкинский р-н'
,'Днепропетровск Коммерческая недвижимость. Аренда Торговые помещения -> Дн-ск. Жовтневый р-н'
,'Днепропетровск Коммерческая недвижимость. Аренда Отдельно стоящие здания (ОСЗ) -> Другие города Украины'
,'Днепропетровск Коммерческая недвижимость. Аренда Производственные помещения. Комплексы -> Дн-ск. Ленинский р-н'
,'Днепропетровск Коммерческая недвижимость. Аренда Складские помещения -> Днепропетровская обл.'
,'Днепропетровск Коммерческая недвижимость. Аренда Складские помещения -> Дн-ск. Амур-Нижнеднепровский р-н'
,'Днепропетровск Коммерческая недвижимость. Аренда Автосервисы. АЗС. Автомойки -> Дн-ск. Амур-Нижнеднепровский р-н'
,'Днепропетровск Коммерческая недвижимость. Аренда Производственные помещения. Комплексы -> Дн-ск. Бабушкинский р-н'
,'Днепропетровск Коммерческая недвижимость. Аренда Складские помещения -> Дн-ск. Жовтневый р-н'
,'Днепропетровск Коммерческая недвижимость. Аренда Автосервисы. АЗС. Автомойки -> Дн-ск. Кировский р-н'
,'Днепропетровск Коммерческая недвижимость. Аренда Другие объекты коммерческого назначения -> Дн-ск. Бабушкинский р-н'
,'Днепропетровск Коммерческая недвижимость. Аренда Производственные помещения. Комплексы -> Дн-ск. Индустриальный р-н'
,'Днепропетровск Коммерческая недвижимость. Аренда Автосервисы. АЗС. Автомойки -> Дн-ск. Красногвардейский р-н'
,'Днепропетровск Коммерческая недвижимость. Аренда Торговые помещения -> Дн-ск. Индустриальный р-н'
,'Днепропетровск Коммерческая недвижимость. Аренда Торговые помещения -> Дн-ск. Ленинский р-н'
,'Днепропетровск Коммерческая недвижимость. Аренда Торговые помещения -> Дн-ск. Амур-Нижнеднепровский р-н'
,'Днепропетровск Коммерческая недвижимость. Аренда Складские помещения -> Дн-ск. Ленинский р-н'
,'Днепропетровск Коммерческая недвижимость. Аренда Другие объекты коммерческого назначения -> Дн-ск. Самарский р-н'
,'Днепропетровск Коммерческая недвижимость. Аренда Объекты сферы обслуживания -> Дн-ск. Кировский р-н'
,'Днепропетровск Коммерческая недвижимость. Аренда Торговые помещения -> Днепропетровская обл.'
,'Днепропетровск Коммерческая недвижимость. Аренда Другие объекты коммерческого назначения -> Дн-ск. Ленинский р-н'
,'Днепропетровск Коммерческая недвижимость. Аренда Другие объекты коммерческого назначения -> Дн-ск. Индустриальный р-н'
,'Днепропетровск Коммерческая недвижимость. Аренда Автосервисы. АЗС. Автомойки -> Другие города Украины'
,'Днепропетровск Коммерческая недвижимость. Аренда Производственные помещения. Комплексы -> Дн-ск. Амур-Нижнеднепровский '
,'Днепропетровск Коммерческая недвижимость. Аренда Складские помещения -> Другие города Украины'
,'Днепропетровск Коммерческая недвижимость. Аренда Складские помещения -> Дн-ск. Кировский р-н'
,'Днепропетровск Коммерческая недвижимость. Аренда Автосервисы. АЗС. Автомойки -> Дн-ск. Индустриальный р-н'
,'Днепропетровск Коммерческая недвижимость. Аренда Объекты сферы обслуживания -> Дн-ск. Индустриальный р-н'
,'Днепропетровск Коммерческая недвижимость. Аренда Другие объекты коммерческого назначения -> Дн-ск. Жовтневый р-н'
,'Днепропетровск Коммерческая недвижимость. Аренда Торговые помещения -> Дн-ск. Красногвардейский р-н'
,'Днепропетровск Коммерческая недвижимость. Аренда Объекты сферы питания -> Дн-ск. Ленинский р-н'
,'Днепропетровск Коммерческая недвижимость. Аренда Другие объекты коммерческого назначения -> Дн-ск. Кировский р-н'
,'Днепропетровск Коммерческая недвижимость. Аренда Другие объекты коммерческого назначения -> Дн-ск. Амур-Нижнеднепровски'
,'Днепропетровск Коммерческая недвижимость. Аренда Отдельно стоящие здания (ОСЗ) -> Дн-ск. Красногвардейский р-н'
,'Днепропетровск Коммерческая недвижимость. Аренда Другие объекты коммерческого назначения -> Другие города Украины'
,'Днепропетровск Коммерческая недвижимость. Аренда Другие объекты коммерческого назначения -> Днепропетровская обл.'
,'Днепропетровск Коммерческая недвижимость. Аренда Складские помещения -> Дн-ск. Индустриальный р-н'
,'Днепропетровск Коммерческая недвижимость. Аренда Объекты сферы питания -> Дн-ск. Красногвардейский р-н'
,'Днепропетровск Коммерческая недвижимость. Аренда Торговые помещения -> Дн-ск. Самарский р-н'
,'Днепропетровск Коммерческая недвижимость. Аренда Автосервисы. АЗС. Автомойки -> Днепропетровская обл.'
);

my %long = ();
for( my $i=1; $i < scalar @a; $i++ ) {
    #say $a[$i];
    my $a0 = encode('utf8', $a[0]);
    my $ai = encode('utf8', $a[$i]);

    my $diff = String::Diff::diff_fully( decode('utf8',$a0), decode('utf8',$a[$i]) );

    say encode('utf8',$diff->[0]->[0]->[1]);
    $long{$diff->[0]->[0]->[1]} = 1;
    say encode('utf8',$diff->[1]->[0]->[1]);
    $long{$diff->[1]->[0]->[1]} = 1;
    say;

next;
    for my $line (@{ $diff->[0] }) {
          print "$line->[0]: '". encode('utf8',$line->[1]). "'\n";
    }
    # u: 'this is '
    # -: 'Perl'

    say;
    say;

    for my $line (@{ $diff->[1] }) {
      print "$line->[0]: '". encode('utf8',$line->[1]). "'\n";
    }
    # u: 'this is '
    # +: 'Ruby'
}

say p %long;
exit 0;

my ($old,$new) = String::Diff::diff( decode('utf8',$a[0]), decode('utf8',$a[1]) );

#say "Old: ", decode('utf8',$old);
#say "New: ", decode('utf8',$new);

say "Old: ", $old;
say "New: ", $new;
