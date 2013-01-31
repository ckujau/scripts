#!/bin/sh
#
# (c) 2009 Christian Kujau <lists@nerdbynature.de>
#
# Rsnapshot wrapper script. For this to work, the rsnapshot.conf
# file for each host must include the following directives:
#
# ##HOST=FQDN PORT=NN OS=Unix TAG=ABC RDY=/var/run/rsnapshot.ready
#
# * The line must begin with two hashmarks (#)
# * HOST will be the FQDN of the machine to be backed up.
# * PORT is the portnumber of the SSH daemon, listening on 
#   remote machine
# * OS is the output of "uname -s" for the remote machine 
#   (if it's a Unix/Linux host)
# * TAG is
# * RDY is a filename which must exist on the remote machine
#   otherwise the backup will not be run.
#   
LANG=C
PATH=/usr/bin:/usr/sbin:/bin:/sbin
CONF=/usr/local/etc/rsnapshot-wrapper.conf

# unset me!
# DEBUG=echo

log() {
echo "`date +%F\ %H:%M:%S\ %Z`: $1"
[ -n "$2" ] && exit "$2"
}

backup() {
INTERVAL="$1"
log "**** ======================================================="
log "**** $INTERVAL backup started..."

# Rsnapshot needs perl anyway but not all systems have GNU/date
BEGIN_G=`perl -e 'print time'`
for c in $CONFDIR/*.conf; do
	echo
	BEGIN=`perl -e 'print time'`

	# We're parsing our configuration file for:
	#
	# - ROOT, RLOG		- standard rsnapshot options
	# - HOST, PORT, OS, TAG	- mandatory for this wrapper
	# - RDY			- we shall only backup if this file exists on the remote host
	#
	# We're using them to identify the system correctly and will only
	# backup if the client wants us to.
	#
	unset ROOT RLOG HOST PORT OS TAG RDY MSG
	eval `awk      '/^snapshot_root/ {print "ROOT="$2}; /^logfile/ {print "RLOG="$2}' $c`
	eval `awk -F\# '/^##HOST=/       {print $3}' "$c"`

	# As "test -w" would return true even when ROOT is mounted r/o, so let's touch(1) it.
	if [ -d "$ROOT" ] && touch "$ROOT" 2>/dev/null; then
		:
	else
		log "**** $ROOT is not a writable directory!"
		continue
	fi
	
	# Only run if there's no successful run today
        # [07/Jun/2012:01:56:57] /usr/bin/rsnapshot -c /etc/rsnapshot/rsnapshot-len.conf daily: ERROR: \
	#			 /usr/bin/rsnapshot -c /etc/rsnapshot/rsnapshot-len.conf daily: completed, but with some errors
	egrep "`date +"%d/%b/%Y"`.*"$CYCLE".*(completed successfully|completed, but with some warnings)" "$RLOG" > /dev/null
	if [ $? = 0 ]; then
		log "**** $HOST/$OS already has a $INTERVAL backup from today, skipping." | tee -a "$RLOG"
		continue
	fi

	# See if the remote system is up & running
	nc -w1 -z $HOST $PORT > /dev/null
	if [ ! $? = 0 ]; then
		log "**** Host $HOST not responding on port $PORT, skipping!"
		continue
	fi

	# We need to know if we're about to backup the correct system, but
	# we can't rely on the system's hostname (think of multiboot systems
	# with the same FQDN and the same SSH hostkeys installed). The hostid
	# should be good enough. Unfortunately, some systems won't provide one
	# and we have to figure out something else.
	case "$OS" in
		Darwin)
		# The respective rsnapshot.conf needs TAG=Darwin for it to be
		# recognized properly.
		TAG2=`ssh -p$PORT $HOST "uname -s" 2>/dev/null`
		;;

		Windows)
		# The respective rsnapshot.conf needs TAG=Windows for it to be
		# recognized properly.
		TAG2="`ssh -p$PORT $HOST \"cygcheck.exe -s\" | awk '/^Windows/ {print $1}'`"
		;;

		*)
		# Unix/Linux systems have "hostid"
		TAG2=`ssh -p$PORT $HOST "hostid" 2>/dev/null`
		;;
	esac

	# See if TAG2 matches the configured TAG
	if [ ! "$TAG" = "$TAG2" ]; then
		log "**** $HOST/$OS: we expected tag \""$TAG"\" but discovered \""$TAG2"\" instead, skipping!"
		continue
	fi

	# See if the remote site wants us to check if we're allowed to backup
	if [ -n "$RDY" ]; then

		# See if the remote site wants us to backup
		TEMP=`$DEBUG mktemp`
		$DEBUG rsync --port="$PORT" $HOST:"$RDY" "$TEMP" 2>/dev/null
		if [ ! $? = 0 ]; then
			log "**** File \""$HOST":"$RDY"\" ($OS) not found, skipping!"
			$DEBUG rm -f "$TEMP"
			echo
			continue
		else
			$DEBUG rm -f "$TEMP"
		fi
	else
		# The remote site wants us to backup, no matter what (no ready-file specified)
		:
	fi

	# Bail out if we're unable to create a logfile	
	if [ ! -f "$RLOG" ]; then
		$DEBUG touch "$RLOG"
		if [ ! $? = 0 ]; then
			log "**** Cannot create $RLOG, skipping."
			continue
		fi
	fi

	# All tests passed, let's do this now
	log "**** $HOST/$OS ($INTERVAL) started..." | tee -a "$RLOG"
	if [ -z "$DEBUG" ]; then
		rsnapshot -c "$c" $INTERVAL >> "$RLOG" 2>&1
	else
		echo rsnapshot -c "$c" $INTERVAL
	fi

	# See if we were successful
	tail -1 "$RLOG" | grep 'completed successfully' 1>/dev/null || MSG="with errors "

	 END=`perl -e 'print time'`
	DIFF=`echo "scale=2; ( $END - $BEGIN ) / 60" | bc -l`
	log "**** $HOST/$OS ($INTERVAL) finished ${MSG}after $DIFF minutes."
done
END_G=`perl -e 'print time'`
DIFF_G=`echo "scale=2; ( $END_G - $BEGIN_G ) / 60" | bc -l`
log "**** $INTERVAL backup finished after $DIFF_G minutes"

# Sync disks
sync
}

# We need a configuration too
if [ ! -f "$CONF" ]; then
	log "Configuration file ($CONF) missing, cannot continue!" 1
else
	. "$CONF"

	# We need these to run
	if [ ! -d "$CONFDIR" -o -z "$LOG" -o -z "$PIDFILE" ]; then
		log "**** Please check CONFDIR, LOG, PIDFILE in $CONF!" 1
	fi

	# We also need configuration file(s)
	ls "$CONFDIR"/*.conf > /dev/null 2>&1
	if [ ! $? = 0 ]; then
		log "**** There are no configuration files in $CONFDIR!" 1
	fi

	# run only once
	PID=`cat "$PIDFILE" 2>/dev/null`
	if [ -n "$PID" ]; then
		ps -p"$PID" > /dev/null
		if [ $? = 0 ]; then
			log "**** There's another instance of `basename $0` running (PID: $PID)" 1
		else
			echo $$ > "$PIDFILE"
		fi
	else
		echo $$ > "$PIDFILE"
	fi
		
fi

# Be nice to others
[ -n "$NICE" ] && renice $NICE $$ > /dev/null

# Main
case $1 in
	hourly|daily|weekly|monthly)
	CYCLE="$1"
	preexec         2>&1 | tee -a $LOG
	backup "$CYCLE" 2>&1 | tee -a $LOG
	postexec        2>&1 | tee -a $LOG
	;;

	stats)
	# Not Y3K safe :-)
	for h in `awk '/^2[0-9].*\((hourly|daily|weekly|monthly)\) finished/ {print $5}' "$LOG" | sort -u`; do
		printf "Host $h took an average of "
		egrep "${h}.*finished" "$LOG" | awk '{sum+=$9} END {print sum/NR " minutes to complete."}'
	done

	echo "----"
	for t in hourly daily weekly monthly; do
		grep "$t" "$LOG" > /dev/null || continue
		printf "The $t backup took an average of "
		egrep "${t} backup finished after" "$LOG" | awk '{sum+=$9} END {print sum/NR " minutes to complete."}'
	done
	;;

	*)
	echo "Usage: `basename $0` [hourly|daily|weekly|monthly]"
	echo "       `basename $0` [stats]"
	exit 1
	;;
esac
