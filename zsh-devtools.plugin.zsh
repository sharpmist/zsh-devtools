# zsh-devtools: git worktree, port and LAN helpers for zsh on macOS.
# Load with any plugin manager, or: source /path/to/zsh-devtools.plugin.zsh

0=${(%):-%N}
ZSH_DEVTOOLS_DIR=${0:A:h}

source "$ZSH_DEVTOOLS_DIR/common.zsh"
source "$ZSH_DEVTOOLS_DIR/help.zsh"
source "$ZSH_DEVTOOLS_DIR/worktrees.zsh"
source "$ZSH_DEVTOOLS_DIR/ports.zsh"
source "$ZSH_DEVTOOLS_DIR/network.zsh"

# Port completion needs compinit; plugin managers run it before loading plugins.
if (( $+functions[compdef] )); then
  compdef _listening_ports killport whoport lanurl
fi
