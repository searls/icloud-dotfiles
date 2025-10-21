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

## /usr/local/bin - apps like aws, code, cursor use this:
export PATH="/usr/local/bin:$PATH"

## Xcode tools
export PATH="$PATH:/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin"

## Need to point @just-every/code to codex explicitly with:
export CODEX_HOME="$HOME/.codex"

# As of 3/12/2024, postgresql@16 is keg-only, so add it to the path
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"

# Force iCloud Drive to download any dotfiles that have been evicted by the
# "Optimize Storage" option being enabled
# macOS 14.0 public beta 3 breaks this
# force-local-icloud-dotfiles

# Define preferred terminal profiles
read -r -d '' PROJECT_PROFILE_MAP <<EOF
$HOME:Basic
$HOME/code/searls/posse_party:Red Sands
$HOME/code/searlsco/searls-auth:Man Page
EOF
export PROJECT_PROFILE_MAP
PROJECT_PROFILE_DEFAULT="Basic"

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

  project_profile_pc() { ~/bin/project_profile || true; }

  # Only modify PROMPT_COMMAND (and load Apple's helper) in Apple Terminal
  if [[ ${TERM_PROGRAM:-} == "Apple_Terminal" ]]; then
    # Prepend safely if PROMPT_COMMAND already exists
    if [[ -n "${PROMPT_COMMAND:-}" ]]; then
      PROMPT_COMMAND="project_profile; ${PROMPT_COMMAND}"
    else
      PROMPT_COMMAND="project_profile"
    fi
    export PROMPT_COMMAND

    # Source Apple's bash integration (defines update_terminal_cwd)
    if [[ -f /etc/bashrc_Apple_Terminal ]]; then
      . /etc/bashrc_Apple_Terminal
    fi
  else
    # In non-Apple terminals, strip any stray update_terminal_cwd to avoid errors
    if [[ "${PROMPT_COMMAND:-}" == *update_terminal_cwd* ]] && ! command -v update_terminal_cwd >/dev/null; then
      _pc="${PROMPT_COMMAND}"
      _pc="${_pc//update_terminal_cwd; /}"
      _pc="${_pc//; update_terminal_cwd/}"
      _pc="${_pc//update_terminal_cwd/}"
      PROMPT_COMMAND="${_pc}"
      unset _pc
      export PROMPT_COMMAND
    fi
  fi

  ### Set up homebrew
  if [ -f $(brew --prefix)/etc/bash_completion ]; then
    source $(brew --prefix)/etc/bash_completion
  fi
fi

# Other Customization

## Editor registration for git, etc
export EDITOR="code-stable --wait"
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
PATH="$PATH:$HOME/.local/bin"

# Custom bash completion for my ~/bin/edit script
source "$HOME/icloud-drive/dotfiles/bash-completions/edit.bash"
