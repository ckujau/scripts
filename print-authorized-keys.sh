#!/bin/sh
#
# (c)2013 Christian Kujau <lists@nerdbynature.de>
#
# There's currently no way to list the fingerprints of all the keys in
# authorized_keys separately. This may be useful to see if a certain
# public key is listed in authorized_keys.
#
# Unfortunately ssh-keygen cannot read from stdin, so we have to use
# a temporary file here.
#

# We need a temporary file, even on MacOS
TEMP=`mktemp 2>/dev/null || mktemp -t authorized_keys 2>/dev/null`
if [ ! -O "$TEMP" ]; then
	echo "Cannot create TEMP file, bailing out!"
	exit 2
fi

i=1
egrep -v '^#|^$' ~/.ssh/authorized_keys | while read l; do
	printf "key: $i  "
	echo "$l" > "$TEMP"
	ssh-keygen -f "$TEMP" -l
	i=$((i+1))
done
rm -f "$TEMP"
