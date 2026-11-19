# List the public commands without running any of them.
devtools() {
  if (( $# > 1 )) || [[ $# == 1 && $1 != -h && $1 != --help ]]; then
    print -u2 -r -- 'Usage: devtools [-h|--help]'
    return 1
  fi

  print -r -- 'zsh-devtools commands

Help
  devtools / zdev [-h|--help]  List available commands

Git worktrees
  fwt / wt                   Pick a worktree and cd into it
  dwt / dw                   Pick a worktree and remove it
  gwl                        List git worktrees
  gsc                        Print the current branch

Ports
  ports [filter]             List listening TCP ports, optionally filtered
  whoport [port]             Show command and working directory; pick if omitted
  killport [port]            Pick listening processes to kill

Network
  lanip                      Print this Mac’s local network IP
  pubip                      Print your public IP
  qr [text]                  Print text and its QR code; default: clipboard
  lanurl [port]              Print a LAN URL and QR code; pick if omitted'
}

alias zdev='devtools'
