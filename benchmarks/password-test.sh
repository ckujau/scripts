#!/bin/sh
#
# Test various password generators and password checkers
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
echo "$FAILED passwords ($(echo "scale=3; $FAILED / $NUM * 100" | bc -l)%) failed for $c, runtime: $(expr $TIME_E - $TIME_S) seconds."
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

# main loop
for c in cracklib pwqcheck; do
	for g in pwgen pwqgen apg gpw makepasswd; do
		printf "$g - "
		TIME_S=$(date +%s)
		FAILED=$(r_$g | r_$c)
		TIME_E=$(date +%s)
		stats $FAILED $NUM $c $TIME_E $TIME_S
	done
	echo
done
