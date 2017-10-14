#!/usr/bin/perl

use strict;
use warnings;

use Text::CSV;
use Net::DNS;
use Net::IP;

my $csv = Text::CSV->new();

my $res = Net::DNS::Resolver->new;

while (<>)
{
   if ($csv->parse($_))
   {
      my @columns = $csv->fields();
      my $sValue = $columns[1];
   }
   else
   {
      my $err = $csv->error_input;
      print "Failed to parse line: $err";
   }
}
close CSV;

#&printcsv;

sub getZone
{
   my $sIP = shift;
   my $query;
   my $getZoneReturns = "Unknown";

   my $sTestIP;
   if ($sTestIP = new Net::IP ($sIP))
   {
      if ($sTestIP->iptype() eq "PUBLIC")
      {
         $getZoneReturns = "Internet";
      }
   }
   return $getZoneReturns;
}


sub getSourceIP
{
   my $sIP = shift;
   my $query;
   my $getSourceIPReturns;

   $query = $res->search($sIP);
   if ($query)
   {
      foreach my $rr ($query->answer)
      {
         if ($rr->type eq "A")
         {
            $sIP = $rr->address;
         }
      }
   }
   return $getSourceIPReturns = "$sIP";
}


#+
#   ip_getip.pl
#
#   Usage: ip_getip.pl [<column>]
#
#   cowro       2011.02.14
#-
