# zsh-devtools: git worktree, port and LAN helpers for zsh on macOS.
# Load with any plugin manager, or: source /path/to/zsh-devtools.plugin.zsh

0=${(%):-%N}
ZSH_DEVTOOLS_DIR=${0:A:h}

if (( ! $+commands[fzf] )); then
  print -u2 "zsh-devtools: fzf not found; the pickers (fwt, dwt, killport, whoport, lanurl) need it. Install with: brew install fzf"
fi

source "$ZSH_DEVTOOLS_DIR/help.zsh"
source "$ZSH_DEVTOOLS_DIR/worktrees.zsh"
source "$ZSH_DEVTOOLS_DIR/ports.zsh"
source "$ZSH_DEVTOOLS_DIR/network.zsh"

# Port completion needs compinit; plugin managers run it before loading plugins.
if (( $+functions[compdef] )); then
  compdef _listening_ports killport whoport lanurl
fi
