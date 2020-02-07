#!/usr/bin/ksh
#
# (C) Mule, 2009-08-07
# The Lolcats, they are everywhere!
# https://web.archive.org/web/20170702162404/http://www.breakingsystemsforfunandprofit.com/the-lolcats-they-are-everywhere/
#
DIR=/var/www/ternet
while read URL; do
	SURL=$(echo "${URL}" | cut -d" " -f1)
	echo "${SURL}" | egrep -qi "\.(jp(e)?g|gif|png|tiff|bmp|ico)$" &&
	(
	umask 002
	PIC=$$-${RANDOM}
	wget -q -O ${DIR}/${PIC}.tmp "${SURL}"
	convert -quiet ${DIR}/${PIC}.tmp -flop ${DIR}/${PIC}.png
	rm -f ${DIR}/${PIC}.tmp
	echo http://127.0.0.1/ternet/${PIC}.png
	) || echo "$URL"
done
