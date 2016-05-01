#!/bin/sh
#
# (c)2009 Christian Kujau <lists@nerdbynature.de>
#
# Check for certain directories to be in place. If they are,
# create a file which says that we're ready to be backed up.
#
PATH=/bin:/usr/bin:/usr/sbin
FILE=/var/run/rsnapshot.ready

# unset me!
# DEBUG=echo

if [ $# = 0 ]; then
	echo "Usage: `basename $0` [dir1] [dir2] [...]"
	exit 1
fi

for d in $@; do
	# normalize
	DIR=`echo $d | sed 's/\/$//'`
	test -n "$DEBUG" && echo "DIR: $DIR"

	# check if we're mounted
	mount | grep "$DIR type" > /dev/null
	if [ $? = 0 ]; then
		$DEBUG touch "$FILE"
	else
		# remove FILE if a single mountpoint was not mounted and bail out
		$DEBUG rm -f "$FILE"
		break
	fi
done
