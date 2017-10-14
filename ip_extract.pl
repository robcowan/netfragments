#!/usr/bin/perl

use Net::IP;

my $sIP;
my $IP;
my $regex_IP = qr/[^\.0-9](\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})[^\.0-9]/;
$regex_IP = qr/(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})[^\.0-9]/;

while (<>)
{
   my $in_line = "<bol>$_<eol>";
   while ($in_line =~ m/$regex_IP/g)
   {
      $sIP = int($1).".".int($2).".".int($3).".".int($4);
      if ($IP = new Net::IP($sIP))
      {
         print "$sIP\n";
      }
   }
}
