#!/usr/bin/perl

my $sMAC;

while (<STDIN>)
{
   while ($_ =~ /[^0-9a-f]((?:[0-9a-f]{2}[:\-\.]?){5}[0-9a-f]{2}|(?:[0-9a-f]{4}[:\-\.]?){3})[^0-9a-f:-]/ig)
   {
      $sMAC = $1;
      $sMAC =~ s/[:\-\.]//g;
      $sMAC = join($ARGV[0], unpack('A2' x 6, $sMAC));
      print "$sMAC\n";
   }
}

# No decimal or no-zero notation..

#   while ($_ =~ /[^0-9a-f]((?:[0-9a-f]{2}[:-]?){5}[0-9a-f]{2})[^0-9a-f]/ig)
