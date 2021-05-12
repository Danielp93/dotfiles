# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

# ENVIRONMENTAL VARIABLES
## Default config location (for XDG honoring binaries)
export XDG_CONFIG_HOME=$HOME/.config

# ALIASSES
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

# Set correct dircolors
eval `dircolors $HOME/.dircolors.wsl`

# Application Specific
if [ -d "$HOME/go" ] ; then
	GOPATH="$HOME/go"
	GOROOT="/opt/go"
	PATH="$PATH:$GOPATH/bin:$GOROOT/bin"
	
fi
# NVM create initfunction, init is too slow for bash startup
initnvm(){
	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash
	export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
}

# Init Pyenv 
initpyenv(){
	export PATH="$HOME/.pyenv/bin:$PATH"
	eval "$(pyenv init -)"
	eval "$(pyenv virtualenv-init -)"
}
