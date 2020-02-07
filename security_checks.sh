#!/bin/sh
#
# (c)2010 Christian Kujau <lists@nerdbynature.de>
#
# Execute a few security checks, keep state across runs.
#   rkhunter: http://rkhunter.sourceforge.net/
#      lynis: https://cisofy.com/lynis/
# chkrootkit: http://www.chkrootkit.org/
#
STATE=/var/run/sec.state
MAXAGE=7
 
# unset me!
# DEBUG=echo
 
# BTS# 231267
if [ -f "$STATE" ] && [ ! -L "$STATE" ]; then
	:
else
	$DEBUG rm -f "$STATE"
	$DEBUG touch "$STATE"
fi
 
check() {
C="$1"
AGE=`echo \( $(date +%s) - $(stat -c %Y "$STATE"."$C") \) / 604800 | bc`
diff -u "$STATE"."$C" "$STATE"."$C".$$ > "$STATE"."$C".diff
 
# If something changed, display the differences
if   [ -s "$STATE"."$C".diff ]; then
	cat "$STATE"."$C".diff
	mv "$STATE"."$C".$$ "$STATE"."$C"
 
# If nothing changed, display statefile anyway (every MAXAGE days)
elif [ "$AGE" -ge $MAXAGE ]; then
	cat "$STATE"."$C"
	rm "$STATE"."$C".$$
 
# If nothing changed, clean up
else
	rm "$STATE"."$C".$$
fi
}
 
 
case $1 in chkrootkit)
	$DEBUG touch "$STATE".chkrootkit
	cd /opt/chkrootkit/sbin
	$DEBUG ./chkrootkit > "$STATE".chkrootkit.$$
	check chkrootkit
	;;
 
	rkhunter)
	$DEBUG touch "$STATE".rkhunter
	$DEBUG /opt/rkhunter/bin/rkhunter --pkgmgr DPKG --nocolors --logfile /var/log/rkhunter.log \
				--skip-keypress --report-warnings-only --check > "$STATE".rkhunter.$$
	check rkhunter
	;;
 
	lynis)
	$DEBUG touch "$STATE".lynis
	cd /opt/lynis
	yes | $DEBUG ./lynis --checkall --no-colors > "$STATE".lynis.$$
	check lynis
	;;
 
	show)
	for c in chkrootkit rkhunter lynis; do
		echo "======= $c ======="
		cat "$STATE"."$c"
	done
	;;
 
	RESET)
	for c in chkrootkit rkhunter lynis; do
		echo > "$STATE"."$c"
	done
	;;
 
	*)
	echo "Usage: `basename $0` [chkrootkit|rkhunter|lynis]"
	echo "		    [show]"
	echo "		    [RESET]"
	exit 1
	;;
esac
