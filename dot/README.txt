These dotfiles are usually executed in this order:

1) .bash_profile, .zprofile	- For login shells
2) .profile			- For login shells (KSH)
2) .bashrc/.kshrc/.zshrc	- depending on the shell being used
3) .aliases			 - called by .bashrc/.kshrc/.zshrc
4) .shell.local			 - called by .bashrc/.kshrc/.zshrc

If you like those, try one of the following:

 > curl      https://raw.githubusercontent.com/ckujau/scripts/master/dot/install-dot.sh | sh
 > fetch -o- https://raw.githubusercontent.com/ckujau/scripts/master/dot/install-dot.sh | sh
 > wget  -O- https://raw.githubusercontent.com/ckujau/scripts/master/dot/install-dot.sh | sh
