#!/bin/sh
#
# (c)2011 Christian Kujau <lists@nerdbynature.de>
# Forcefully rotate rsnapshot backups, intentionally discarding older copies
#
CONF="/etc/rsnapshot"

if [ ! $# = 1 ]; then
	HOSTS=`ls "$CONF"/rsnapshot-*.conf | sed 's/.*\/rsnapshot-//;s/\.conf//' | xargs echo | sed 's/ /|/g'`
	echo "Usage: `basename $0` [$HOSTS]"
	exit 1
else
	CONF="$CONF"/rsnapshot-"$1".conf
	 DIR=`awk '/^snapshot_root/ {print $2}' $CONF`

	# Don't let rsnapshot-wrapper remount our backup store
	WRAPPER_CONF="/usr/local/etc/rsnapshot-wrapper.conf"
	     NOMOUNT=$(awk -F= '/^NOMOUNT/ {print $2}' $WRAPPER_CONF)
	touch "$NOMOUNT"

	[ -f "$CONF" ] || exit 2
	[ -d "$DIR"  ] || exit 3
fi

for i in daily weekly monthly; do
	C=`ls -d "$DIR"/"$i".* 2>/dev/null | wc -l`
	j=0
	while [ $j -le $C ]; do
		echo "("$j"/"$C") rsnapshot -c "$CONF" "$i"..."
		rsnapshot -c "$CONF" "$i"
		j=$((j+1))
	done
done

# Since this is not a normal operation and may take a long time, we will
# remove the NOMOUNT flag again, otherwise we may forget to remove it.
rm -f "$NOMOUNT"
