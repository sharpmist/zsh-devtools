# IP of this Mac on the local network (the default route's interface).
lanip() {
  _devtools_require ipconfig route || return 1
  local interface address
  interface=$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')
  if [[ -z $interface ]]; then
    print -u2 'zsh-devtools: no default network interface found.'
    return 1
  fi
  address=$(ipconfig getifaddr "$interface")
  if [[ -z $address ]]; then
    print -u2 'zsh-devtools: no local IPv4 address found.'
    return 1
  fi
  print -r -- "$address"
}

# Public IP, via api.ipify.org.
pubip() {
  _devtools_require curl || return 1
  local address
  address=$(curl -fsS --max-time 3 https://api.ipify.org) || return 1
  [[ -n $address ]] || return 1
  print -r -- "$address"
}

# Print a URL (or any text) and its QR code (if qrencode is installed).
# qr https://example.com, or run qr with no argument to use the clipboard
qr() {
  (( $# <= 1 )) || { print -u2 'Usage: qr [text]'; return 1; }
  local text=$1
  if (( $# == 0 )); then
    _devtools_require pbpaste || return 1
    text=$(pbpaste) || return 1
  fi
  if [[ -z $text ]]; then
    echo "Usage: qr <url>, or copy a URL and run qr" >&2
    return 1
  fi
  print -r -- "$text"
  if command -v qrencode >/dev/null 2>&1; then
    qrencode -t ansiutf8 "$text"
  fi
}

# URL (+ QR code if qrencode is installed) for testing on a phone.
# lanurl 5173, or run lanurl with no port to pick a LAN-reachable port with fzf
lanurl() {
  (( $# <= 1 )) || { print -u2 'Usage: lanurl [port]'; return 1; }
  if (( $# )); then _devtools_validate_port "$1" || return 1; fi
  local port=$1 list address
  if [[ -z $port ]]; then
    _devtools_require lsof fzf || return 1
    # Only ports bound to all interfaces (*:port) can be reached from another device
    list=$(lsof -nP +c 0 -iTCP -sTCP:LISTEN | awk 'NR==1 || $9 ~ /^\*:/')
    if (( $(wc -l <<< "$list") < 2 )); then
      echo "No LAN-reachable ports. Start the dev server with --host (e.g. pnpm start --host)." >&2
      return 1
    fi
    port=$(fzf --exit-0 --header-lines=1 --header="Select port" <<< "$list" \
      | awk '{ n = split($9, a, ":"); print a[n] }')
    [[ -z $port ]] && return 1
  fi
  _devtools_validate_port "$port" || return 1
  address=$(lanip) || return 1
  qr "http://$address:$port"
}
