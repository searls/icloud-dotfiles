export PATH="/usr/local/bin:$PATH"

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# added by travis gem
[ -f /Users/justin/.travis/travis.sh ] && source /Users/justin/.travis/travis.sh

# The next line updates PATH for Netlify's Git Credential Helper.
if [ -f '/Users/justin/.netlify/helper/path.bash.inc' ]; then source '/Users/justin/.netlify/helper/path.bash.inc'; fi
