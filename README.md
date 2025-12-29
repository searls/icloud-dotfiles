# icloud-dotfiles

Having been burned a few times by different dotfiles strategies, I decided to
just roll my own. Feel free to copy this if you're so inclined.

The basic gist of this:

1. Store dotfiles in iCloud Drive
2. Have a script that symlinks iCloud drive & dotfiles to my home directory and
    installs the programs I use, such that it can be re-run gracefully

Here's my [full routine for setting up a new Mac on YouTube](https://blog.testdouble.com/talks/2020-05-28-setting-up-a-new-mac-for-development/)

## Setup

### 1. Fetch the dotfiles and throw them in iCloud Drive

Fork this repo and clone it into your iCloud Drive as "dotfiles" like so:

```
$ git clone --recursive https://github.com/searls/icloud-dotfiles.git "~/Library/Mobile Documents/com~apple~CloudDocs/dotfiles"
```

### 2. Run the setup script

Now, run the initial setup script (which you can review
[here](https://github.com/searls/icloud-dotfiles/blob/master/bin/strap)):

```
$ ~/Library/Mobile\ Documents/com~apple~CloudDocs/dotfiles/bin/strap
```

In my case, this:

- Creates symlinks from `$HOME` into iCloud Drive (dotfiles + `~/.Brewfile`)
- Applies Homebrew state via `brew bundle` (from `.Brewfile`)
- Applies macOS defaults I care about
- Switches my login shell to Homebrew bash
- Bootstraps Postgres (creates a default DB if missing)
- Installs pinned Node and Ruby versions via `nodenv`/`rbenv`
- Installs a small set of Ruby gems
- Copies LaunchAgents into `~/Library/LaunchAgents`
- Sources `~/.profile`
