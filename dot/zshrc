#
# ~/.zshrc
#
export HISTSIZE=10000
export SAVEHIST=10000
export HISTFILE="$HOME"/.zsh_histfile
export HISTCONTROL=ignoredups
export HOSTNAME=$(hostname | awk -F\. '{print $1}')	# hostname -s is not portable

if [ "$USER" = "root" ]; then
	export PS1="${HOSTNAME}# "
	alias la='ls -lha'
else
	export PS1="${USER}@${HOSTNAME}$ "
	alias la='ls -lh'
fi

if [ -f "$HOME"/.zshrc.local ]; then
	. "$HOME"/.zshrc.local
fi
