#!/bin/sh
#
# (c)2011 lists@nerdbynature.de
# Forcefully rotate rsnapshot backups, intentionally discard older copies
#
if [ ! $# = 1 ]; then
	echo "Usage: `basename $0` [host]"
	exit 1
else
	CONF=/etc/rsnapshot/rsnapshot-"$1".conf
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
