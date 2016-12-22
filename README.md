# icloud-dotfiles

Having been burned a few times by different dotfiles strategies, I decided to
just roll my own. Feel free to copy this if you're so inclined.

The basic gist of this:

1. Store dotfiles in iCloud Drive
2. Store secure dotfiles (e.g. environment variables) in an encrypted disk image
   in iCloud Drive
3. Have a script that symlinks iCloud drive & dotfiles to my home directory and
    installs (or updates) the programs I use, such that it can be re-run gracefully

## Setup

### 1. Fetch the dotfiles and throw them in iCloud Drive

Fork this repo and clone it into your iCloud Drive as "dotfiles" like so:

```
$ git clone https://github.com/searls/icloud-dotfiles.git "~/Library/Mobile Documents/com~apple~CloudDocs/dotfiles"
```

### 2. Create an encrypted disk image

Create an encrypted disk image named "secure.dmg" with volume label
"secure-dotfiles" and place it inside the "dotfiles" directory.

![screen shot 2016-12-22 at 1 16 00 pm](https://cloud.githubusercontent.com/assets/79303/21435652/eff8ddcc-c848-11e6-9214-e010f718a24f.png)

Once created, open the disk image, and check the box to add the password to your
Keychain.

Next, create any files that need to be stored securely. In my case this was:

```
$ touch /Volumes/secure-dotfiles/.env
$ touch /Volumes/secure-dotfiles/.homebridge-config.json
```

Finally, add the disk image to your login items so that it's always available
while you're logged in:

<img width="668" alt="screen shot 2016-12-22 at 1 18 46 pm" src="https://cloud.githubusercontent.com/assets/79303/21435696/2f2621a8-c849-11e6-991a-cda9edff1c9c.png">

### 3. Run the setup script

Now, run the initial setup script (which you can review
[here](https://github.com/searls/icloud-dotfiles/blob/master/bin/setup-new-mac)):

```
$ ~/Library/Mobile\ Documents/com~apple~CloudDocs/dotfiles/bin/setup-new-mac
```

In my case, this sets up my symlinks, installs/updates my brew formulas,
sets up Node & Ruby, mounts my encrypted dotfiles and then sources my bash
profile.

