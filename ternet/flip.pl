#!/usr/bin/perl
#
# (c) Pete Stevens
# http://www.ex-parrot.com/~pete/upside-down-ternet.html
#
$|=1;
$count = 0;
$pid = $$;
$tmp = "/var/www/ternet";
while (<>) {
	chomp $_;
	if ($_ =~ /(.*\.jpg)/i) {
		$url = $1;
		system("/usr/bin/wget", "-q", "-O","$tmp/$pid-$count.jpg", "$url");
		system("/usr/bin/mogrify", "-flip","$tmp/$pid-$count.jpg");
		print "http://127.0.0.1/ternet/$pid-$count.jpg\n";
	}
	elsif ($_ =~ /(.*\.gif)/i) {
		$url = $1;
		system("/usr/bin/wget", "-q", "-O","$tmp/$pid-$count.gif", "$url");
		system("/usr/bin/mogrify", "-flip","$tmp/$pid-$count.gif");
		print "http://127.0.0.1/ternet/$pid-$count.gif\n";
	}
	elsif ($_ =~ /(.*\.png)/i) {
		$url = $1;
		system("/usr/bin/wget", "-q", "-O","$tmp/$pid-$count.png", "$url");
		system("/usr/bin/mogrify", "-flip","$tmp/$pid-$count.png");
		print "http://127.0.0.1/ternet/$pid-$count.png\n";
	}
	else {
		print "$_\n";;
	}
	$count++;
}
