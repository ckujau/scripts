#!/bin/sh
#
# (C)2009 lists@nerdbynature.de
#
# We once had a one-liner to backup all our databases:
#    $ mysqldump -AcfFl --flush-privileges | pbzip2 -c > backup.sql.bz2
#
# However, most of the databases do not change much or do not change at
# over the day, yet the resulting .bz2 had to be generated every day,
# *did* change and, worst of all: had to be transferred in full over a
# 128 kbps line to our backup host. This one is slightly more complicated,
# but should suffice.
#
# Privileges needed: SELECT, RELOAD, LOCK TABLES
#
PATH=/bin:/usr/bin:/usr/local/bin
HASH=sha1			# See 'openssl dgst -h' for possible values

# unset me!
# DEBUG=echo

if [ ! -d "$1" ]; then
	echo "Usage: `basename $0` [dir] [-c]"
	exit 1
else
	DIR="$1"
fi

# Use 'gdate' if available, 'date' otherwise
if [ "`which gdate`" ]; then
	DATE=gdate
else
	DATE=date
fi

$DATE
# We have checks too :-)
if [ "$2" = "-c" ]; then
	for f in "$DIR"/*.bz2; do
		printf "Processing $f (`stat -c 'scale=0; %s / 1024' $f | bc -l`KB)..."
		grep -q `bzip2 -dc "$f" | openssl $HASH` `echo $f | sed "s/.bz2$/.$HASH/"`
		if [ $? = 0 ]; then
			echo "checksum OK"
		else
			echo "checksum FAILED"
		fi
	done
exit 0
fi

BEGIN=`$DATE +%s`
for db in `mysql --batch --skip-column-names -e 'show databases' | sort`; do
	printf "Backing up "$db"...."
	# - Use multiple-row INSERT syntax that include several VALUES lists
	# - Continue even if an SQL error occurs during a table dump
	# - Flush the MySQL server log files before starting the dump
	# - Send a FLUSH PRIVILEGES statement to the server after dumping the mysql database
	# - Lock all tables to be dumped before dumping them
	# - Dump binary columns using hexadecimal notation
	# - Using --skip-dump-date (added in v5.0.52) so that the dump won't change unnecessarily.
	# - Included stored routines
	# - Include triggers for each dumped table
	case "$db" in
	performance_schema|information_schema)
		# Access denied for user 'root'@'localhost' to database 'information_schema' when using LOCK TABLES
		# http://bugs.mysql.com/bug.php?id=21527 (closed)
		# http://bugs.mysql.com/bug.php?id=33762 (closed)
		# http://bugs.mysql.com/bug.php?id=49633
		OPTIONS="--extended-insert --force --flush-logs --flush-privileges --skip-lock-tables --hex-blob --routines --triggers"
	;;

	*)
		OPTIONS="--extended-insert --force --flush-logs --flush-privileges --lock-tables      --hex-blob --routines --triggers"
	;;
	esac

	if [ -n "$DEBUG" ]; then
		$DEBUG mysqldump $OPTIONS "$db"   egrep -v -- '^-- Dump completed on'   "$DIR"/DB_"$db".sql.new
	else
		$DEBUG mysqldump $OPTIONS "$db" | egrep -v -- '^-- Dump completed on' > "$DIR"/DB_"$db".sql.new
	fi
	
	# We're comparing checksum rather than the whole dump, so that we
	# can compress them afterwards and still be able to compare tomorrow's dump.
	# - If  a checksum file is present, create a new one and compare them
	# - If no checksum file is present, create one
	if [ -f "$DIR"/DB_"$db".sql.$HASH ]; then
		if [ -n "$DEBUG" ]; then
			$DEBUG openssl $HASH "$DIR"/DB_"$db".sql.new   sed 's/\.new$//'   "$DIR"/DB_"$db".sql.new.$HASH
		else
			$DEBUG openssl $HASH "$DIR"/DB_"$db".sql.new | sed 's/\.new$//' > "$DIR"/DB_"$db".sql.new.$HASH
		fi
		H_OLD=`awk '{print $NF}' "$DIR"/DB_"$db".sql.$HASH     2>/dev/null`
		H_NEW=`awk '{print $NF}' "$DIR"/DB_"$db".sql.new.$HASH 2>/dev/null`
		
		# - If they are equal, delete our new one, otherwise update the old one
		if [ "$H_OLD" = "$H_NEW" ]; then
			echo "database $db has not changed, nothing to do."
			$DEBUG rm "$DIR"/DB_"$db".sql.new "$DIR"/DB_"$db".sql.new.$HASH
		else
			echo "database $db changed!"
			$DEBUG mv "$DIR"/DB_"$db".sql.new.$HASH "$DIR"/DB_"$db".sql.$HASH
			$DEBUG mv "$DIR"/DB_"$db".sql.new       "$DIR"/DB_"$db".sql
			$DEBUG pbzip2 -f "$DIR"/DB_"$db".sql
		fi
	else
		# - We have nothing to compare
		echo "database $db must be new?"
		$DEBUG mv "$DIR"/DB_"$db".sql.new "$DIR"/DB_"$db".sql
		if [ -n "$DEBUG" ]; then
			$DEBUG openssl $HASH "$DIR"/DB_"$db".sql   "$DIR"/DB_"$db".sql.$HASH
		else
			$DEBUG openssl $HASH "$DIR"/DB_"$db".sql > "$DIR"/DB_"$db".sql.$HASH
		fi
		$DEBUG pbzip2 -f "$DIR"/DB_"$db".sql
	fi
	$DEBUG
done
END=`$DATE +%s`
echo "$0 finished after `echo $END - $BEGIN | bc` seconds."
echo
