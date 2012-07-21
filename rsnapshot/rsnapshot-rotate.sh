#!/bin/sh
#
# (c) 2011 Christian Kujau <lists@nerdbynature.de>
#
# Forcefully rotate rsnapshot backups, intentionally discard older copies
#
CONF="/etc/rsnapshot"

if [ ! $# = 1 ]; then
	HOSTS=`ls "$CONF"/rsnapshot-*.conf | sed 's/.*\/rsnapshot-//;s/\.conf//' | xargs echo | sed 's/ /|/g'`
	echo "Usage: `basename $0` [$HOSTS]"
	exit 1
else
	CONF="$CONF"/rsnapshot-"$1".conf
	 DIR=`awk '/^snapshot_root/ {print $2}' $CONF`

	[ -f "$CONF" ] || exit 2
	[ -d "$DIR"  ] || exit 3
fi

for i in daily weekly monthly; do
	C=`ls -d "$DIR"/"$i".* | wc -l`
	j=0
	while [ $j -le $C ]; do
		echo "("$j"/"$C") rsnapshot -c "$CONF" "$i"..."
		rsnapshot -c "$CONF" "$i"
		j=$((j+1))
	done
done
