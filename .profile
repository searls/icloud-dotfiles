# Initialize homebrew
eval $(/opt/homebrew/bin/brew shellenv)

# Initialize my "xenv" language runtime managers if installed
if command -v rbenv &>/dev/null; then
  eval "$(rbenv init -)"
fi
if command -v nodenv &>/dev/null; then
  eval "$(nodenv init -)"
fi
if command -v pyenv &>/dev/null; then
  eval "$(pyenv init --path)"
fi

# Additional PATH configuration

## My own scripts - take priority
export PATH="$HOME/bin:$PATH"

# As of 3/12/2024, postgresql@16 is keg-only, so add it to the path
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"

## My GPT scripts - not priority
export PATH="$PATH:$HOME/code/searls/gpt_scripts/script"

# Force iCloud Drive to download any dotfiles that have been evicted by the
# "Optimize Storage" option being enabled
# macOS 14.0 public beta 3 breaks this
# force-local-icloud-dotfiles

# Shell-specific settings

if [[ "$SHELL" == *zsh ]]; then
  # Nothing to see here
  true
elif [[ "$SHELL" == *bash ]]; then
  ## Bash settings

  ### stickier .bash_history
  export HISTCONTROL=ignoredups:erasedups  # no duplicate entries
  export HISTSIZE=100000                   # big big history
  export HISTFILESIZE=100000               # big big history
  shopt -s histappend                      # append to history, don't overwrite it

  # Save and reload the history after each command finishes
  # export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

  ### Set up homebrew
  if [ -f $(brew --prefix)/etc/bash_completion ]; then
    source $(brew --prefix)/etc/bash_completion
  fi
fi

# Other Customization

## Editor registration for git, etc
export EDITOR="vim"
export LC_CTYPE="en_US.UTF-8"

## Reference the location of iCloud Drive
export ICLOUD_DRIVE="$HOME/icloud-drive"

## Source ENV variables
source "$ICLOUD_DRIVE/dotfiles/.env"

## Set fzf to use rg like so for ctrl-t in shell:
export FZF_DEFAULT_COMMAND='rg --files --ignore --hidden --follow --glob "!.git/*"'
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

## Increase limit of open file descriptors because watch processes
ulimit -n 10000

## load custom PS1 prompt
source $HOME/bin/ps1

# update_terminal_cwd() {
#     # Identify the directory using a "file:" scheme URL,
#     # including the host name to disambiguate local vs.
#     # remote connections. Percent-escape spaces.
#     local SEARCH=' '
#     local REPLACE='%20'
#     local PWD_URL="file://$HOSTNAME${PWD//$SEARCH/$REPLACE}"
#     printf '\e]7;%s\a' "$PWD_URL"
# }

## Enable Homebrew bash completions
# https://docs.brew.sh/Shell-Completion
if type brew &>/dev/null
then
  HOMEBREW_PREFIX="$(brew --prefix)"
  if [[ -r "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh" ]]
  then
    source "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh"
  else
    for COMPLETION in "${HOMEBREW_PREFIX}/etc/bash_completion.d/"*
    do
      [[ -r "${COMPLETION}" ]] && source "${COMPLETION}"
    done
  fi
fi
