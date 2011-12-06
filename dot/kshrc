#
# ~/.kshrc
#
export HOSTNAME=`uname -n`
if [ "$USER" = "root" ]; then
	export PS1="${HOSTNAME}# "
	alias la='ls -lha'
else
	export PS1="${USER}@${HOSTNAME}$ "
	alias la='ls -lh'
fi

export HISTFILE="$HOME"/.ksh_history
export HISTSIZE=10000
export TERM=xterm-color
export GREP_OPTIONS='--color=tty --devices=skip'
export PAGER='less'
export LESS='--ignore-case --squeeze-blank-lines --no-init'
export EDITOR=vi

alias mv='mv -iv'
alias cp='cp -iv'
alias rm='rm -iv'

set -o emacs		# Try 'vi' for a change :-)
