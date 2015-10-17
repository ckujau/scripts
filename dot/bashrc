#
# ~/.bashrc
#
export HISTTIMEFORMAT="%F %T "
export HISTSIZE=10000
export HISTCONTROL=ignoredups
shopt -s histappend
export PROMPT_COMMAND="history -a"

if [ $UID = 0 ]; then
	export PS1="\h# "
	alias la="ls -lha"
else
	export PS1="\u@\h$ "
	alias la="ls -lh"
fi


# Enable bash-completion only if not in POSIX mode
# https://www.gnu.org/software/bash/manual/html_node/Bash-POSIX-Mode.html
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
	. /etc/bash_completion
fi

[ -r $HOME/.aliases     ] && . $HOME/.aliases
[ -r $HOME/.shell.local ] && . $HOME/.shell.local
