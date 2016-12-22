# icloud-dotfiles

Having been burned a few times by different dotfiles strategies, I decided to
just roll my own. Feel free to copy this if you're so inclined.

The basic gist of this:

1. Store dotfiles in iCloud Drive
2. Store secure dotfiles (e.g. environment variables) in an encrypted disk image
   in iCloud Drive
3. Symlink iCloud Drive to my home directory
4. Symlink all my dotfiles from iCloud Drive to my home directory
5. Have a script that installs (or updates) all of the programs I
   typically need, such that it can be re-run gracefully

## Initial setup

Fork this repo and clone it into your iCloud Drive as "dotfiles":

```
$ git clone https://github.com/searls/icloud-dotfiles.git "/Users/justin/Library/Mobile Documents/com~apple~CloudDocs/dotfiles"
```


