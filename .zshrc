# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH
umask 002
ZSH_DISABLE_COMPFIX=true
#. "${HOME}/.cache/wal/colors.sh"
###### Exports ######

#export PATH="/usr/lib/jvm/java-11-openjdk-amd64/bin:$PATH"

export PATH="${PATH}:${HOME}/.local/bin"
export ZSH="$HOME/.oh-my-zsh"
export PATH=$PATH:~/bin
export PATH="/usr/lib/jvm/java-17-openjdk-amd64/bin:$PATH"
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

#export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
#export PATH=$JAVA_HOME/bin:$PATH

export PATH=$PATH:/home/hieroja/.spicetify
export TERM=xterm-256color
export PYTHONPATH=~:$PYTHONPATH
#export LESSOPEN="| grep -P 'alias|$' --color=always %s"
export LESSOPEN="|pygmentize -g %s"
export LESS='-R'
bindkey -s '\e[15~' '!!\n\n'


ZSH_THEME="robbyrussell"
HISTSIZE=5000
SAVEHIST=5000
HIST_STAMPS="dd.mm.yyyy"

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  copyfile
  catimg
  #fzf-tab
)

ZSH_AUTOSUGGEST_STRATEGY="match_prev_cmd" #"completion"
source $ZSH/oh-my-zsh.sh

if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_ed25519
fi

#disable underline
(( ${+ZSH_HIGHLIGHT_STYLES} )) || typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[path]=none
ZSH_HIGHLIGHT_STYLES[path_prefix]=none

autoload -Uz compinit && compinit

CURRENT_ACTIVITY="$(~/scripts/get-current-activity-name.sh)"

if [ "$CURRENT_ACTIVITY" = "Work" ]; then
  HISTDIR=~/.zsh_history_archive_work
  HISTFILE=~/.zsh_history_work
  sort -f ~/.zsh_aliases_work -o ~/.zsh_aliases_work
  source ~/.zsh_aliases_work
else
  HISTDIR=~/.zsh_history_archive
  HISTFILE=~/.zsh_history
fi

sort -f ~/.zsh_aliases -o ~/.zsh_aliases
source ~/.zsh_aliases

archive_history() {
  if [ $(wc -l < "$HISTFILE") -ge 5000 ]; then
      mv "$HISTFILE" "$HISTDIR/zsh_history_$(date +%Y%m%d%H%M%S)"
      touch "$HISTFILE"
  fi
}

precmd() {
  archive_history
}

#export FZF_DEFAULT_OPTS="--color 16"
export FZF_DEFAULT_OPTS="
  --color 16
  --color hl:09,fg+:015,bg+:05,hl+:09
  --color info:008,prompt:003,spinner:011,pointer:006,marker:002
  --cycle
  --prompt='❯ ' #❯
  --pointer=''
  --marker='│'
  --layout=reverse
  --bind=tab:down,shift-tab:up
"

alias upp="sudo apt update && sudo apt upgrade -y"
alias kate="kate -n"
alias colors=". ~/dotfiles/scripts/pywal/colors.sh"
alias pare="./dotfiles/scripts/pywal/run-pywal.sh --theme 'parecolors'"
alias pywal-debug="./dotfiles/scripts/pywal/pywal-debug.sh"

alias find="echo 'Files: Ctrl+T\nText:  grep <text>'" #"fzf"
alias ls="eza --icons -F -H --group-directories-first --git -1"
alias tree="eza --icons --tree -F -H"
alias cd="z"
alias cat="bat"
alias grep="rg"
alias dolphin="dolphin . >/dev/null & disown > /dev/null"

precmd() { precmd() { echo } }
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
source <(fzf --zsh)
eval "$(zoxide init zsh)"

#export NVM_DIR="$HOME/.nvm"
#[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
#[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


eval "$(starship init zsh)"
