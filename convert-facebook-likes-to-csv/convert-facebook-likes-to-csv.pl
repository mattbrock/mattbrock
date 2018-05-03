#!/usr/bin/perl

# 1. Copy all liked pages from Facebook profile
#    to a text file called "data.txt".
#
# 2. CD to the directory containing data.txt
#    and run this script, redirecting output
#    to a CSV file which can be opened in a 
#    spreadsheet.

open(my $fh, "<", "data.txt")
  or die "Can't open < data.txt: $!";

my @data;

{ local $/ = '';
  @data = <$fh>; }

close $fh;

my @sorted_data = sort { lc($a) cmp lc($b) } @data;

foreach $block (@sorted_data) {
  print $_, ", " for split '\n', $block;
  print "\n";
}
