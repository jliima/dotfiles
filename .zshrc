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

export PATH=$PATH:$HOME/.spicetify
export TERM=xterm-256color
export PYTHONPATH=~:$PYTHONPATH
#export LESSOPEN="| grep -P 'alias|$' --color=always %s"
export LESSOPEN="|pygmentize -g %s"
export LESS='-R'
#bindkey -s '\e[15~' '!!\n\n'


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

export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

#disable underline
(( ${+ZSH_HIGHLIGHT_STYLES} )) || typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[path]=none
ZSH_HIGHLIGHT_STYLES[path_prefix]=none

autoload -Uz compinit && compinit

CURRENT_ACTIVITY=$(plasma-activities-cli6 --current-activity | awk '{print $3}')

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

alias upp="$HOME/scripts/kde/update-packages.sh"
alias kate="kate -n"
alias colors="bash ~/dotfiles/scripts/pywal/colors.sh"
alias pare="$HOME/dotfiles/scripts/pywal/run-pywal.py"
alias pywal-debug="./dotfiles/scripts/pywal/pywal-debug.sh"
alias tg='python3 $HOME/scripts/telegram-video-converter.py'

alias ls="eza --icons -F -H --group-directories-first --git -1"
alias cd="z"
alias cat="bat"
alias grep="rg"
alias find="echo 'Files: Ctrl+T\nText:  grep <text>'" #"fzf"
alias tree="eza --icons --tree -F -H"
alias dolphin="dolphin . >/dev/null & disown > /dev/null"
alias neofetch="fastfetch"

precmd() { precmd() { echo } }
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
source <(fzf --zsh)
eval "$(zoxide init zsh)"

# Only for interactive shells
if [[ $- == *i* ]]; then
  export NVM_DIR="$HOME/.nvm"

  # Loader: source nvm and bash_completion, then undefine stubs so calls go directly to real commands
  _load_nvm() {
    # Prevent repeated loading
    unset -f node npm pnpm npx nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
  }

  # Stub wrappers: load on first use, then forward the arguments
  nvm() { _load_nvm; nvm "$@"; }
  node() { _load_nvm; command node "$@"; }
  npm() { _load_nvm; command npm "$@"; }
  pnpm() { _load_nvm; command pnpm "$@"; }
  npx() { _load_nvm; command npx "$@"; }
fi

yt-dlp() {
  # If node is still a shell function (lazy stub), load nvm
  if [[ "$(whence -w node)" == *"function"* ]]; then
    _load_nvm
  fi

  command yt-dlp "$@"
}

tg-dlp() {
  yt-dlp \
    --no-playlist \
    -f "bv*[ext=mp4][vcodec^=avc1][height<=1080]+ba[ext=m4a]/b[ext=mp4][height<=1080]" \
    --merge-output-format mp4 \
    --embed-thumbnail \
    --add-metadata \
    "$@"
}

eval "$(starship init zsh)"
