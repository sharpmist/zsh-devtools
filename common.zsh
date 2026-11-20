# Check dependencies only when needed; sourcing the plugin stays quiet.
_devtools_require() {
  local dependency
  for dependency in "$@"; do
    if ! command -v "$dependency" >/dev/null 2>&1; then
      print -u2 -r -- "zsh-devtools: missing dependency: $dependency (install it and retry)."
      return 1
    fi
  done
}

# Validate before passing user input to lsof or constructing a URL.
_devtools_validate_port() {
  if [[ -z $1 || $1 == *[^0-9]* || ${#1} -gt 5 ]] ||
     (( 10#$1 < 1 || 10#$1 > 65535 )); then
    print -u2 -r -- "zsh-devtools: invalid port '$1'; expected a decimal number from 1 to 65535."
    return 1
  fi
}
