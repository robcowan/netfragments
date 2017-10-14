#!/usr/bin/perl

$ipn = $ARGV[0];

$ipn    %= (256**4);
$octet1 = int ($ipn / (256**3));
$ipn    %= ($octet1 * 256**3);
$octet2 = int ($ipn / (256**2));
$ipn    %= ($octet2 * 256**2);
$octet3 = int ($ipn / 256);
$octet4 = $ipn % ($octet3 * 256);

print "$octet1.$octet2.$octet3.$octet4\n";
