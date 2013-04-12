#!/bin/sh
#
# (c) Public Domain
#
# Tries to verify if SSH_ORIGINAL_COMMAND is really 
# rsync/uname/whatever and return false if not.
#
case "$SSH_ORIGINAL_COMMAND" in
	rsync\ --server*|uname\ -s|hostid)
	$SSH_ORIGINAL_COMMAND
	;;

	*)
	exit 1
	;;
esac 
