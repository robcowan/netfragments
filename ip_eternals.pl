#!/usr/bin/perl

use Net::IP;

my $IP;
my $sType = "PRIVATE";

while (<>)
{
   if ($IP = new Net::IP($_))
   {
      if ($IP->iptype() ne "$sType")
      {
         print;
      }
   }
}
