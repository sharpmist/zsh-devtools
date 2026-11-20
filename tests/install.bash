#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home with spaces"
export ZDOTDIR="$tmp/zsh config"
mkdir -p "$ZDOTDIR"
printf '# existing config\n' > "$ZDOTDIR/.zshrc"
./install >/dev/null
./install >/dev/null
line='source "$HOME/.local/share/zsh-devtools/zsh-devtools.plugin.zsh"'
[[ $(grep -Fxc "$line" "$ZDOTDIR/.zshrc") == 1 ]]
grep -Fqx '# existing config' "$ZDOTDIR/.zshrc"
for file in ./*.zsh; do
  cmp "$file" "$HOME/.local/share/zsh-devtools/${file##*/}"
done
printf 'outdated\n' > "$HOME/.local/share/zsh-devtools/help.zsh"
./install >/dev/null
cmp help.zsh "$HOME/.local/share/zsh-devtools/help.zsh"
zsh -f -c 'source "$ZDOTDIR/.zshrc"; devtools >/dev/null; (( $+aliases[zdev] ))'
./install --help >/dev/null
if ./install --invalid >/dev/null 2>&1; then exit 1; fi
unset ZDOTDIR
./install >/dev/null
[[ -f "$HOME/.zshrc" ]]
printf 'PASS: installer creation, updates, idempotence, ZDOTDIR, and spaces\n'
