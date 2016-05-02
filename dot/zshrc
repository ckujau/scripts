#
# ~/.zshrc
#
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=$HOME/.zsh_histfile

setopt append_history		# append, rather than replace history file entries
setopt extended_history		# save timestamp & duration
setopt hist_ignore_dups		# don't save duplicate history entries
setopt hist_verify		# don't execute, only expand history
setopt inc_append_history	# add commands as soon as they're entered
setopt share_history		# import & append new commands to/from history file

bindkey -e			# use EMACS keymap
bindkey '^R' history-incremental-search-backward

alias  history="fc -t '%Y-%m-%d %H:%M:%S' -l 0"

if [ $LOGNAME = 0 ]; then
	PS1="${HOST}# "
	alias la='ls -lha'
else
	PS1="${LOGNAME}@${HOST}$ "
	alias la='ls -lh'
fi

# Enable ZSH completion
autoload -U compinit && compinit -i

[ -r $HOME/.aliases     ] && . $HOME/.aliases
[ -f $HOME/.shell.local ] && . $HOME/.shell.local
