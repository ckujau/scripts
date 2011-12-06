#
# ~/.bashrc
#
if [ $UID = 0 ]; then
	export PS1='\h# '
	alias la='ls -lha'
else
	export PS1='\u@\h$ '
	alias la='ls -lh'
fi

shopt -s histappend
history -n
export PROMPT_COMMAND='history -a'
export HISTTIMEFORMAT='%F %T '
export HISTSIZE=10000
export HISTCONTROL=ignoredups
export GREP_OPTIONS='--color=tty --devices=skip'
export PAGER='less'
export LESS='--ignore-case --squeeze-blank-lines --no-init'
export EDITOR=vi

alias mv='mv -iv'
alias cp='cp -iv'
alias rm='rm -iv'

if [ -z "$BASH_COMPLETION" -a -f /etc/bash_completion ]; then
	. /etc/bash_completion
fi

if [ -f "$HOME"/.bashrc.local ]; then
	. "$HOME"/.bashrc.local
fi
