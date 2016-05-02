#
# ~/.kshrc
#
export HISTFILE=$HOME/.ksh_history
export HISTSIZE=10000
export HOSTNAME=$(uname -n | cut -d\. -f1)
export FCEDIT='/bin/false'

if [ "$LOGNAME" = "root" ]; then
	export PS1="${HOSTNAME}# "
	alias la='ls -lha'
else
	export PS1="${LOGNAME}@${HOSTNAME}$ "
	alias la='ls -lh'
fi

set -o emacs						# Try 'vi' for a change :-)

[ -r $HOME/.aliases     ] && . $HOME/.aliases
[ -r $HOME/.shell.local ] && . $HOME/.shell.local
