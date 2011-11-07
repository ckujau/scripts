#!/bin/sh
#
# (c) 2009 lists@nerdbynature.de
# Rsnapshot wrapper script
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

# Rsnapshot needs perl anyway, and not all systems have GNU/date
BEGIN_G=`perl -e 'print time'`
for c in $CONFDIR/*-*.conf; do
	echo
	BEGIN=`perl -e 'print time'`

	# We're parsing our configuration file for:
	# - ROOT, RLOG		- standard rsnapshot options
	# - HOST, PORT, OS, TAG	- mandatory for this wrapper
	# - RDY			- we shall only backup if this file exists on the remot host
	# We're using them to identify the system correctly and will only
	# backup if the client wants us to.
	#
	unset ROOT RLOG HOST PORT OS TAG RDY MSG
	eval `awk      '/^snapshot_root/ {print "ROOT="$2}; /^logfile/ {print "RLOG="$2}' $c`
	eval `awk -F\# '/^##HOST=/       {print $3}' "$c"`

	if [ ! -d "$ROOT" -o ! -w "$ROOT" ]; then
		log "**** $ROOT is not a writable directory!"
		continue
	fi

	# See if the remote system is up & running
	nc -w1 -z $HOST $PORT
	if [ ! $? = 0 ]; then
		log "**** Host $HOST not responding on port $PORT, skipping!"
		continue
	fi

	# We need to know if we're about to backup the correct system, but
	# we can't rely on e.g. SSH hostkeys (think of multiboot systems with
	# the same DNS name). The hostid should be good enough. Unfortunately,
	# MacOSX doesn't provide one and we're down to the OS again - oh well.
	case "$OS" in
		Darwin)
		TAG2=`ssh -p$PORT $HOST "uname -s" 2>/dev/null`
		;;

		*)
		TAG2=`ssh -p$PORT $HOST "hostid" 2>/dev/null`
		;;
	esac

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

	# All tests passed, we'll do the backup now
	log "**** $HOST/$OS ($INTERVAL) started..." | tee -a "$RLOG"
	$DEBUG rsnapshot -c "$c" $INTERVAL >> "$RLOG" 2>&1

	# See if we were successful
	tail -1 "$RLOG" | grep 'completed successfully' 1>/dev/null || MSG="with errors "

	END=`perl -e 'print time'`
	DIFF=`echo "scale=2; ( $END - $BEGIN ) / 60" | bc -l`
	log "**** $HOST/$OS ($INTERVAL) finished ${MSG}after $DIFF minutes."
done
END_G=`perl -e 'print time'`
DIFF_G=`echo "scale=2; ( $END_G - $BEGIN_G ) / 60" | bc -l`
log "**** $INTERVAL backup finished after $DIFF_G minutes"
}

# We need a configuration too
if [ ! -f "$CONF" ]; then
	log "Configuration file ($CONF) missing, cannot continue!" 1
else
	. "$CONF"

	# We need these to run
	if [ -z "$CONFDIR" -o -z "$LOG" -o -z "$PIDFILE" ]; then
		log "**** Please check that CONFDIR, LOG, PIDFILE is set in $CONF!" 1
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

# be nice to others
[ -n "$NICE" ] && renice $NICE $$ > /dev/null

case $1 in
	hourly|daily|weekly|monthly)
	preexec     2>&1 | tee -a $LOG
	backup "$1" 2>&1 | tee -a $LOG
	postexec    2>&1 | tee -a $LOG
	;;

	stats)
	for h in `awk '/\) finished/ {print $5}' "$LOG" | sort -u`; do
		printf "Host $h took an average of "
		egrep "${h}.*finished" "$LOG" | awk '{sum+=$9} END {print sum/NR " minutes to complete."}'
	done

	echo "----"
	for t in hourly daily weekly monthly; do
		grep -q "$t" "$LOG" || continue
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
