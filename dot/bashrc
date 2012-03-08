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

export PROMPT_COMMAND='history -a'
export TERM=xterm-color
export HISTTIMEFORMAT='%F %T '
export HISTSIZE=10000
export HISTCONTROL=ignoredups
export GREP_OPTIONS='--color=tty --devices=skip'
export PAGER='less'
export LESS='--ignore-case --squeeze-blank-lines --no-init'
export EDITOR=vi

alias mv='mv -i'
alias cp='cp -i'
alias rm='rm -i'

if [ -f "$HOME"/.bashrc.local ]; then
	. "$HOME"/.bashrc.local
fi

if [ -z "$BASH_COMPLETION" ]; then
	[ -f /etc/bash_completion ] && . /etc/bash_completion
	[ -f /opt/local/etc/bash_completion ] && . /opt/local/etc/bash_completion
fi

