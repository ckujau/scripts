#!/bin/sh
#
# (c)2015 Christian Kujau <lists@nerdbynature.de>
# Install dot files to the current working directory
#

# curl? wget? fetch?
[ `which curl  2>/dev/null` ] && PROG="curl --insecure --output"
[ `which fetch 2>/dev/null` ] && PROG="fetch --no-verify-peer --output"
[ `which wget  2>/dev/null` ] && PROG="wget --no-check-certificate --output-document"

if [ -z "$PROG" ]; then
	echo "No download program found. Install \"curl\", \"wget\" or \"fetch\" and try again!"
	exit 1
else
	for f in aliases bash_profile bashrc kshrc profile screenrc tmux.conf vimrc wgetrc zprofile zshrc; do
		[ -f ."$f" ] && mv ."$f" ."$f".bak.$$
		$PROG ."$f" https://raw.githubusercontent.com/ckujau/scripts/master/dot/"$f"
	done
	BACKUP_FILES=$(ls -d .*.bak.* 2>/dev/null | xargs echo)
	[ -z "$BACKUP_FILES" ] || echo "Backup files can be removed with: rm $BACKUP_FILES"

	# ZSH uses .zprofile instead of .profile
	[ -e .zprofile ] || ln -s .profile .zprofile
fi
