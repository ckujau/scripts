#!/usr/bin/perl
#
# (c)2011 Christian Kujau <lists@nerdbynature.de>
# Make Perl count :-)
#
use strict;

my $c=0;
my $e=$ARGV[0];
my $l=length($e);

while ($c <= $e) {
        my $s=sprintf("%0${l}d", $c);
        printf "$s\n";
        $c ++;
}
