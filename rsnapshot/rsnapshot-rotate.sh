#!/bin/sh
#
# (c)2011 Christian Kujau <lists@nerdbynature.de>
# Forcefully rotate rsnapshot backups, intentionally discarding older copies
#
CONF="/etc/rsnapshot"

if [ ! $# = 1 ]; then
	HOSTS=$(find ${CONF} -maxdepth 1 -name "*.conf" | sed 's/.*\/rsnapshot-//;s/\.conf//' | xargs echo | sed 's/ /|/g')
	echo "Usage: $(basename "$0") [${HOSTS}]"
	exit 1
else
	CONF="${CONF}/rsnapshot-${1}.conf"
	 DIR="$(awk '/^snapshot_root/ {print $2}' "${CONF}")"

	# Safety belt
	[ -f "${CONF}" ] || exit 2
	[ -d "${DIR}"  ] || exit 3
fi

set -e
# Don't let rsnapshot-wrapper remount our backup store while we are running.
NOMOUNT=$(awk -F= '/^NOMOUNT/ {print $2}' /usr/local/etc/rsnapshot-wrapper.conf)
touch "${NOMOUNT}"

for interval in daily weekly monthly; do
	COUNT=$(find "${DIR}"/${interval}.[0-9] -maxdepth 0 2>/dev/null | wc -l)
	j=0
	while [ "${j}" -le "${COUNT}" ]; do
		echo "(${j}/${COUNT}) rsnapshot -c ${CONF} ${interval}..."
		rsnapshot -c "${CONF}" "${interval}"
		j=$((j+1))
	done
done

# Since this is not a normal operation and may take a long time, we will
# remove the NOMOUNT flag again, otherwise we may forget to remove it.
rm -f "${NOMOUNT}"
