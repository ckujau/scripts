#!/bin/sh
#
# (c)2009 Christian Kujau <lists@nerdbynature.de>
#
# We once had a one-liner to backup all our databases:
#
#  $ mysqldump -AcfFl --flush-privileges | pbzip2 -c > backup.sql.bz2
#
# However, most of the databases do not change much or do not change at all
# over the day, yet the resulting compressed dump had to be generated every
# day, *did* change and had to be transferred in full over a 128 kbps line
# to our backup host. This one is slightly more complicated, but should do
# the trick.
#
# Notes:
# - If INFORMATION_SCHEMA.TABLES would work for InnoDB tables, we could query if the
#   database has changed, and only backup if needed.
#   * https://bugs.mysql.com/bug.php?id=2681
#     Ability to determine when DB was last modified (generic method)
#
# - We had to drop the sys.metrics view. The whole sys schema may not be needed at all.
# * https://mariadb.com/kb/en/sys-schema/
# * https://mariadb.com/kb/en/sys-schema/
# * https://forums.cpanel.net/threads/remove-sys-database-after-upgrade-to-from-mysql-5-7-to-mariadb-10-3.674045/
#   > "MariaDB does not utilize the sys schema. If you upgrade from MySQL 5.7 to MariaDB, you must
#   > manually remove the sys database, because it can cause unnecessary errors during certain check table calls."
#
#
    PATH=/bin:/usr/bin:/usr/local/bin
   RUNAS=mysql				# Privileges needed: SELECT, RELOAD, LOCK TABLES
COMPRESS=zstd
 LOGFILE=backup-mysql.log

# unset me!
# DEBUG=echo

if [ ! -d "$1" ]; then
	echo "Usage: $(basename "$0") [dir] [-c]"
	exit 1
else
	DIR="$1"
	cd "$DIR" || exit 3
fi

# Don't run as root, but we need to own $DIR
if [ ! "$(whoami)" = "${RUNAS}" ]; then
	echo "Please execute as user \"${RUNAS}\"!"
	exit 2
fi

# Be nice to others
renice 20 $$ > /dev/null

# The date should end up in a logfile
date >> "${LOGFILE}"

# We have checks too :-)
if [ "$2" = "-c" ]; then
	for f in *.zst; do
		printf "%s" "Processing \"$f\" ($(stat -c 'scale=0; %s / 1024' "$f" | bc -l) KB)..."
		if grep -q "$(${COMPRESS} -qdc "$f" | sha1sum | awk '{print $1}')" "${f%%.zst}".sha1; then
			echo "checksum OK"
		else
			echo "checksum FAILED"
		fi
	done
exit $?
fi

# DB credentials
OPTIONS="--user=backup --password=XXXX"				# Can't we just use ~/.my.cnf?

# Main loop
BEGIN=$(date +%s)
for db in $(mysql ${OPTIONS} --batch --skip-column-names -e 'show databases' | sort); do
	case "${db}" in
	information_schema|performance_schema)
		# Access denied for user 'root'@'localhost' to database 'information_schema' when using LOCK TABLES
		# http://bugs.mysql.com/bug.php?id=21527 (closed)
		# http://bugs.mysql.com/bug.php?id=33762 (closed)
		# http://bugs.mysql.com/bug.php?id=49633
		# OPTIONS="${OPTIONS} --skip-lock-tables"
		continue
	;;

	# mysql)
	#	# - Skip mysql.event, http://bugs.mysql.com/bug.php?id=68376
	#	# - We used to add --skip-events b/c of http://bugs.debian.org/673572 - but this triggers #68376 again!
	#	OPTIONS="${OPTIONS} --ignore-table=mysql.event"
	# ;;
	esac

	# Backup!
	$DEBUG mysqldump ${OPTIONS} --lock-tables --skip-dump-date --result-file="DB_${db}.sql.new" --databases "${db}"
	
	# We're comparing checksums rather than the whole dump, so that we can compress
	# them afterwards and still be able to compare tomorrow's dump.
	# - If  a checksum file is present, create a new one and compare them
	# - If no checksum file is present, create one
	if [ -f DB_"${db}".sql.sha1 ]; then
		$DEBUG sha1sum DB_"${db}".sql.new > DB_"${db}".sql.new.sha1
		sed 's/\.new$//' -i DB_"${db}".sql.new.sha1

		H_OLD=$(awk '{print $1}' DB_"${db}".sql.sha1     2>/dev/null)
		H_NEW=$(awk '{print $1}' DB_"${db}".sql.new.sha1 2>/dev/null)
		
		# If they are equal, delete our new one, otherwise update the old one
		if [ "$H_OLD" = "$H_NEW" ]; then
			echo "Database ${db} has not changed, nothing to do" >> "${LOGFILE}"
			$DEBUG rm DB_"${db}".sql.new DB_"${db}".sql.new.sha1
		else
			echo "Database ${db} has changed, discarding the old dump." >> "${LOGFILE}"
			$DEBUG mv -f DB_"${db}".sql.new.sha1 DB_"${db}".sql.sha1
			$DEBUG mv -f DB_"${db}".sql.new      DB_"${db}".sql
			$DEBUG ${COMPRESS} --rm -9qf DB_"${db}".sql
		fi
	else
		# We have nothing to compare
		echo "No checksum found for database ${db}." >> "${LOGFILE}"
		$DEBUG mv -f DB_"${db}".sql.new DB_"${db}".sql
		$DEBUG sha1sum DB_"${db}".sql > DB_"${db}".sql.sha1
		$DEBUG ${COMPRESS} --rm -9qf DB_"${db}".sql
	fi
done
END=$(date +%s)
echo "${0} finished after $(echo \( "${END}" - "${BEGIN}" \) / 60 | bc) minutes." >> "${LOGFILE}"
echo >> "${LOGFILE}"

### OLD ###
#	printf "%s" "Backing up \"${db}\"...." >> "${LOGFILE}"
	# - Use multiple-row INSERT syntax that include several VALUES lists
	# - Continue even if an SQL error occurs during a table dump
	# - Flush the MySQL server log files before starting the dump
	# - Send a FLUSH PRIVILEGES statement to the server after dumping the mysql database
	# - Dump binary columns using hexadecimal notation
	# - Using --skip-dump-date (added in v5.0.52) so that the dump won't change unnecessarily.
	# - Included stored routines
	# - Include triggers for each dumped table
#	OPTIONS="${OPTIONS} --extended-insert --force --flush-logs --flush-privileges --hex-blob --skip-dump-date --routines --triggers"
