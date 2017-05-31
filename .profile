# Initialize my "xenv" language runtime managers if installed
if command -v rbenv &>/dev/null; then
  eval "$(rbenv init -)"
fi
if command -v nodenv &>/dev/null; then
  eval "$(nodenv init -)"
fi
if command -v pyenv &>/dev/null; then
  eval "$(pyenv init -)"
fi

# Additional PATH configuration

## My own scripts
PATH="$HOME/bin:$PATH"

## Ruby binstubs (note: this can be exploited at untrusted working directories!)
PATH="$PATH:./bin"


# Bash settings

## stickier .bash_history
shopt -s histappend

## Set up tab-completion (requires `brew install bash-completion`)
if [ -f $(brew --prefix)/etc/bash_completion ]; then
  source $(brew --prefix)/etc/bash_completion
fi


# Other Customization

## Editor registration for git, etc
export EDITOR="$VISUAL"
export LC_CTYPE="en_US.UTF-8"

## Reference the location of iCloud Drive
export ICLOUD_DRIVE="$HOME/icloud-drive"

## Source ENV variables
source "$ICLOUD_DRIVE/dotfiles/.env"

## Increase limit of open file descriptors because watch processes
ulimit -n 10000

## Set a few aliases
alias be="bundle exec"
alias gpp="git pull --rebase && git push"
alias gc="git commit"

## load custom PS1 prompt
source $HOME/bin/ps1


export PATH="$HOME/.cargo/bin:$PATH"
