#!/usr/bin/perl
#

# slightly modified

sub _humanHier {
  my $hier=shift;
#return $hier;
  $hier =~ s/^Недвижимость\s*\W?//;
  $hier =~ s/\D(\d{2,}:)//g;
  #$hier =~ s/=/ &gt; /g;
  $hier =~ s/=/ -> /g;
  $hier =~ s/Днепропетровск\./Дн-ск./;
#  $hier =~ s/Киев\.//;
#  $hier =~ s/Коммерческая/Коммерч./;
  #$hier =~ s/=/*/g;
  return $hier;
}
1;

