alias c="clear"
alias ed="cursor /Users/kylehe/dotfiles"

# Add Sublime Text to PATH
export PATH="/Applications/Sublime Text.app/Contents/SharedSupport/bin:$PATH"

autoload -U colors && colors
setopt PROMPT_SUBST
PROMPT='%F{green}%n@%m %F{blue}%~ %F{red}%#%f '