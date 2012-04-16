#!/usr/bin/perl -w
#
# Based on http://blog.koehntopp.de/archives/1172-MySQL-fuer-Dummies-2.html
#
use File::Basename;

if ( @ARGV != 1 ) {
	print "Usage: " . basename($0) . " \[n\]\n";
	print "\#ARGV: $#ARGV\n";
	print "\@ARGV: " . scalar @ARGV . "\n";
	exit;
}
else {
	$limit = $ARGV[0];
	print "\#ARGV: $#ARGV\n";
	print "\@ARGV: " . scalar @ARGV . "\n";
}

for (my $i=0; $i<$limit; $i++) {
	$str1 = "";
	for (my $j=0; $j<10; $j++) {
		$str1 .= chr(97+26*rand());
	}

	$str2 = "";
	for (my $j=0; $j<32; $j++) {
		$str2 .= chr(97+26*rand());
	}

	$x = int(rand()*2**31);
	printf qq("$i","$str1","$str2","$x"\n);
}
