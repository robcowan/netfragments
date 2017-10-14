#!/usr/bin/perl

while (<STDIN>)
{
   local $/=undef;
   open(CMDCURL, "/usr/bin/curl -L -s -m 25 http://standards.ieee.org/cgi-bin/ouisearch?" . substr($_,0,6) . " |");
   binmode(CMDCURL);
   $meezdata = <CMDCURL>;
   close CMDCURL;
   $meezdata =~ m/.*\<pre\>(.*)\<\/pre\>/s;
   $meezdata = $1;
   $meezdata =~ s/<b>//;
   $meezdata =~ s/<\/b>//;
   print $meezdata;
}
