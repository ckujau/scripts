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
	for f in bashrc kshrc profile screenrc tmux.conf vimrc wgetrc zshrc; do
		mv ."$f" ."$f".bak.$$ 2>/dev/null 
		$PROG ."$f" https://raw.githubusercontent.com/ckujau/scripts/master/dot/"$f"
	done
	echo "Backup files can be removed with: rm $(ls -d .*.bak.* | xargs echo)"

	# ZSH uses .zprofile instead of .profile
	[ -e .zprofile ] || ln -s .profile .zprofile
fi
