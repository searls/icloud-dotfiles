tap "heroku/brew"
tap "homebrew/services"
tap "rhettbull/osxphotos"
tap "searlsco/tap"

# Shell + editor baseline (what I want on every machine)
# - bash: my preferred interactive shell (I set it as my login shell)
brew "bash"
# - bash-completion@2: tab completion for CLI tools in bash
brew "bash-completion@2"

# Core CLI utilities (used constantly; also show up in other scripts/config)
brew "coreutils"
# - fzf: interactive fuzzy finder (hooked up in `.profile`)
brew "fzf"
# - ripgrep: fast text search (also wired into fzf CTRL-T via `.profile`)
brew "ripgrep"
# - tree: quick directory visualization
brew "tree"
# - jq: JSON inspection/transform
brew "jq"
# - wget: simple file retrieval
brew "wget"

# Git tooling
# - git: source control
brew "git"
# - gh: GitHub CLI
brew "gh"

# Terminal multiplexer + editor
# - tmux: long-running dev sessions
brew "tmux"
# - vim: always-available editor
brew "vim"

# JavaScript toolchain
# - nodenv + node-build: manage Node versions explicitly
brew "nodenv"
brew "node-build"
# - yarn: JS package manager
brew "yarn"

# Ruby toolchain
# - rbenv + ruby-build: manage Ruby versions explicitly
brew "rbenv"
brew "ruby-build"

# Python toolchain
# - pyenv: manage Python versions explicitly
brew "pyenv"

# Database
# - postgresql@16: local dev DB; auto-start via brew services when installed/updated
brew "postgresql@16", restart_service: :changed

# Publishing
# - hugo: static site generator
brew "hugo"

# Multimedia / AV (used by scripts in `bin/`)
# - ffmpeg: used by `bin/mkv2mp4`, `bin/trimify`, `bin/webpify`, `bin/speed-up-video`, etc.
brew "ffmpeg"

# Platform CLIs
# - heroku: used for Heroku app management/deploys
brew "heroku/brew/heroku"

# Photo + podcast tooling (custom scripts in `bin/`)
# - osxphotos: used by `bin/export_photo_album`
brew "rhettbull/osxphotos/osxphotos"
# - autochapter: used by `bin/autochapter_breaking_change`
brew "searlsco/tap/autochapter"

# Browser
cask "ungoogled-chromium"
