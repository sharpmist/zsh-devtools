# IP of this Mac on the local network (the default route's interface).
lanip() { ipconfig getifaddr "$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')"; }

# Public IP, via api.ipify.org.
pubip() { curl -s --max-time 3 https://api.ipify.org; echo; }

# Print a URL (or any text) and its QR code (if qrencode is installed).
# qr https://example.com, or run qr with no argument to use the clipboard
qr() {
  local text=${1:-$(pbpaste)}
  if [[ -z $text ]]; then
    echo "Usage: qr <url>, or copy a URL and run qr" >&2
    return 1
  fi
  echo "$text"
  command -v qrencode >/dev/null && qrencode -t ansiutf8 "$text"
}

# URL (+ QR code if qrencode is installed) for testing on a phone.
# lanurl 5173, or run lanurl with no port to pick a LAN-reachable port with fzf
lanurl() {
  local port=$1 list
  if [[ -z $port ]]; then
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
  qr "http://$(lanip):$port"
}
