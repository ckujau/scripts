#!/bin/sh
#
# (c)2014 Christian Kujau <lists@nerdbynature.de>
# Test various password generators and password checkers
#
# Needs the following programs installed:
# cracklib-runtime, passwdqc, pwgen, apg, gpw, makepasswd, openssl, GNU/parallel
#

# Number of passwords required
if [ -z "$1" ]; then
	echo "Usage: $(basename $0) [lenth] [num]"
	exit 1
else
	LEN="$1"
	NUM="$2"
fi

stats() {
# arguments: FAILED, NUM, TYPE, TIME_E, TIME_S
echo "$FAILED passwords ($(echo "scale=2; $FAILED / $NUM * 100" | bc -l)%) failed for $c, runtime: $(expr $TIME_E - $TIME_S) seconds."
}

# Password checkers
r_cracklib() {
parallel --pipe /usr/sbin/cracklib-check | fgrep -c -v ': OK'
}

r_pwqcheck() {
parallel --pipe pwqcheck -1 --multi | fgrep -c -v 'OK:'
}

# Password generators
r_pwgen() {
pwgen -s -1 $LEN $NUM
}

r_pwqgen() {
i=0; while [ $i -lt $NUM ]; do
	pwqgen | cut -c-"$LEN" | egrep -o "^.{$LEN}$" && i=$((i+1))
done
}

r_apg() {
apg -a 1 -m $LEN -x $LEN -n $NUM
}

r_gpw() {
gpw $NUM $LEN
}

r_makepasswd() {
makepasswd --chars=$LEN --count=$NUM
}

r_openssl() {
yes openssl rand -base64 16 | head -"$NUM" | parallel | cut -c-"$LEN"
}

# main loop
for c in cracklib pwqcheck; do
	for g in pwgen pwqgen apg gpw makepasswd openssl; do
		printf "%10s - %s" $g
		TIME_S=$(date +%s)
		FAILED=$(r_$g | r_$c)
		TIME_E=$(date +%s)
		stats $FAILED $NUM $c $TIME_E $TIME_S
	done
	echo
done
