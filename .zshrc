# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH
umask 002
ZSH_DISABLE_COMPFIX=true

################################################################################
# Exports
################################################################################

export ZSH="$HOME/.oh-my-zsh"
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export RIPGREP_CONFIG_PATH="$HOME/.config/ripgreprc"
export TERM=xterm-256color
export PYTHONPATH="$HOME${PYTHONPATH:+:$PYTHONPATH}"
export LESSOPEN="|pygmentize -g %s"
export LESS="-R"
export MANROFFOPT="-c"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
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

# PATH setup (order matters)
export PATH="$JAVA_HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.spicetify:$PATH"
export PATH="$HOME/scripts/work-scripts:$PATH"

################################################################################
# Oh-My-Zsh Configuration
################################################################################

ZSH_THEME="robbyrussell"
HISTSIZE=5000
SAVEHIST=5000
HIST_STAMPS="yyyy-mm-dd"

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  copyfile
  catimg
  #fzf-tab
)

ZSH_AUTOSUGGEST_STRATEGY="match_prev_cmd" #"completion"

################################################################################
# Activity-based history
################################################################################

CURRENT_ACTIVITY=$("$HOME/scripts/kde/get-current-activity-name.sh" 2>/dev/null)


if [[ "$CURRENT_ACTIVITY" == "Work" ]]; then
  HISTDIR="$HOME/.zsh_history_archive_work"
  HISTFILE="$HOME/.zsh_history_work"
else
  HISTDIR="$HOME/.zsh_history_archive"
  HISTFILE="$HOME/.zsh_history"
fi

mkdir -p "$HISTDIR"
touch "$HISTFILE"

################################################################################
# Functions
################################################################################

archive_history() {
  local line_count
  line_count=$(wc -l < "$HISTFILE")

  if (( line_count >= SAVEHIST )); then
      mv "$HISTFILE" "$HISTDIR/zsh_history_$(date +%Y%m%d%H%M%S)"
      touch "$HISTFILE"
  fi
}

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

################################################################################
# Oh-My-Zsh Initialization
################################################################################

source "$ZSH/oh-my-zsh.sh"

# Disable underline in syntax highlighting
(( ${+ZSH_HIGHLIGHT_STYLES} )) || typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[path]=none
ZSH_HIGHLIGHT_STYLES[path_prefix]=none

source "$HOME/dotfiles/scripts/pywal/run-pywal-completion.bash"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
source <(fzf --zsh)
eval "$(zoxide init zsh)"
export _ZO_DOCTOR=0
eval "$(starship init zsh)"

[[ -f "$HOME/scripts/work-scripts/workrc" ]] && source "$HOME/scripts/work-scripts/workrc"
[[ "$TERM_PROGRAM" == "vscode" ]] && . "$(code --locate-shell-integration-path zsh)"
. "$HOME/.local/bin/env"

################################################################################
# Interactive Shell Settings (NVM and lazy loading)
################################################################################

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

################################################################################
# Aliases
################################################################################

if [[ -f "$HOME/.zsh_aliases" ]]; then
  sort -f "$HOME/.zsh_aliases" -o "$HOME/.zsh_aliases"
  source "$HOME/.zsh_aliases"
fi

if [[ "$CURRENT_ACTIVITY" == "Work" && -f "$HOME/.zsh_aliases_work" ]]; then
  sort -f "$HOME/.zsh_aliases_work" -o "$HOME/.zsh_aliases_work"
  source "$HOME/.zsh_aliases_work"
fi

alias run-pywal="$HOME/dotfiles/scripts/pywal/run-pywal.py"
alias upp="$HOME/scripts/kde/update-packages.sh"
alias kate="kate -n"
alias colors-show="python3 $HOME/dotfiles/scripts/pywal/display-colors-cli.py"
alias tg="python3 $HOME/scripts/telegram-video-converter.py"
alias edit-video="$HOME/scripts/video/edit-video.py"

alias ls="eza --icons -F -H --group-directories-first -w 80"
alias la="eza --icons -F -H --group-directories-first -w 80 -a"
alias cd="z"
alias tree="eza --icons --tree -F -H"
alias dolphin="dolphin . >/dev/null & disown > /dev/null"
alias neofetch="fastfetch"

################################################################################
# Binds
################################################################################

# Bind Ctrl+backspace to erase the previous word
bindkey '^H' backward-kill-word

################################################################################
# Command Hooks
################################################################################

# Adds a blank line before each prompt EXCEPT the first prompt just after starting the shell.
precmd() {
  archive_history
  [[ -n "$_PRECMD_RAN_ONCE" ]] && echo
  _PRECMD_RAN_ONCE=1
}
