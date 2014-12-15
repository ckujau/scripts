#!/bin/sh
#
# Install dot files to the current working directory
#

# curl? wget? fetch?
[ `which curl` ]  && PROG="curl --insecure --output"
[ `which wget` ]  && PROG="wget --no-check-certificate --output-document"
[ `which fetch` ] && PROG="fetch --no-verify-peer --output"

if [ -z "$PROG" ]; then
	echo "No download program found. Install \"curl\", \"wget\" or \"fetch\" and try again!"
	exit 1
else
	for f in bashrc kshrc profile screenrc tmux.conf vimrc wgetrc; do
		mv ."$f" ."$f".bak.$$ 2>/dev/null 
		$PROG ."$f" https://raw.githubusercontent.com/ckujau/scripts/master/dot/"$f"
	done
fi
