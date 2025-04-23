
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

#eval "$(dircolors ~/.dircolors)"
autoload -Uz compinit && compinit
#zstyle '*:completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}'
#zstyle ':completion:*:directories'  list-colors '=*=32'
#PS1="$fg[green]%}-> $fg[blue]%}%~$fg[white]%}\$ "
PROMPT='%{$fg[green]%}-> %{$fg[blue]%}%~%{$fg[white]%}$ %{$fg[white]%}'
#setopt no_list_ambiguous

#current_activity=$(qdbus org.kde.ActivityManager /ActivityManager/Activities ActivityName `qdbus org.kde.ActivityManager /ActivityManager/Activities CurrentActivity`)

if [ "$current_activity" = "Work" ]; then
  HISTDIR=~/zsh-work/history
  HISTFILE=~/zsh-work/history/zsh_history
  if [ -f ~/zsh-work/scripts/generate_script_aliases.sh ]; then
    . ~/zsh-work/scripts/generate_script_aliases.sh
  fi
  source /home/hieroja/zsh-work/aliases-work

else
  HISTDIR=~/zsh-personal/history
  HISTFILE=~/zsh-personal/history/zsh_history
  if [ -f ~/zsh-personal/scripts/generate_script_aliases.sh ]; then
    . ~/zsh-personal/scripts/generate_script_aliases.sh
  fi
  source /home/hieroja/zsh-personal/aliases-personal

fi

archive_history() {
  if [ $(wc -l < "$HISTFILE") -ge 5000 ]; then
      mv "$HISTFILE" "$HISTDIR/zsh_history_$(date +%Y%m%d%H%M%S)"
      touch "$HISTFILE"
  fi
}

precmd() {
  archive_history
}

alias kubuntu_version="
echo 'lsb_release -a : \n' &&
lsb_release -a &&
echo '\nuname -m && cat /etc/*release : \n' &&
uname -m && cat /etc/*release
echo '\nuname -srmv : \n' &&
uname -srmv
"
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

alias kate="kate -n"
alias colors=". ~/pywal/scripts/colors.sh"
alias pare="./pywal/scripts/run-pywal.sh --theme 'parecolors'"
alias pywal-debug="./pywal/scripts/pywal-debug.sh"

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
