#!/usr/bin/perl

use Data::Dumper;
use JSON;

my $json = new JSON;

$json_string = { IP => qq/172.16.1.1/,LAST => qq/1.1.1.1/ };
$json_string    = to_json($json_string);

print $json_string . "\n";

$shit = decode_json($json_string);

print Dumper $shit;

print "\n\nIP == " . $shit->{"IP"} . "\n";
