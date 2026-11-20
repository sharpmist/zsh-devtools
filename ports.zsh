# Kill listening process(es); port is optional. TAB to multi-select.
killport() {
  (( $# <= 1 )) || { print -u2 'Usage: killport [port]'; return 1; }
  if (( $# )); then _devtools_validate_port "$1" || return 1; fi
  _devtools_require lsof fzf ps || return 1
  setopt localoptions pipefail
  local selection
  local -a pids
  selection=$(lsof -nP +c 0 -iTCP${1:+:$1} -sTCP:LISTEN \
    | fzf -m --exit-0 --header-lines=1 \
          --header="Select process(es) to kill${1:+ on port $1}" \
          --preview 'ps -o command= -p {2}; lsof -a -p {2} -d cwd -Fn | sed -n "s/^n/cwd: /p"' \
          --preview-window=down,3,wrap) || return 1
  [[ -n $selection ]] || return 1
  pids=(${(f)"$(awk '$2 ~ /^[0-9]+$/ && $2 > 0 {print $2}' <<< "$selection" | sort -u)"})
  (( ${#pids} )) || return 1
  kill -- "${pids[@]}"
}

# List listening TCP ports, optionally filtered: ports | ports node
ports() {
  (( $# <= 1 )) || { print -u2 'Usage: ports [filter]'; return 1; }
  _devtools_require lsof || return 1
  lsof -nP +c 0 -iTCP -sTCP:LISTEN | awk -v q="$1" 'NR==1 || tolower($0) ~ tolower(q)'
}

# Full command line + working directory of whatever listens on a port.
# whoport 5173, or run whoport with no port to pick one with fzf
whoport() {
  (( $# <= 1 )) || { print -u2 'Usage: whoport [port]'; return 1; }
  if (( $# )); then _devtools_validate_port "$1" || return 1; fi
  _devtools_require lsof ps || return 1
  local port=$1 pids pid
  if [[ -z $port ]]; then
    _devtools_require fzf || return 1
    port=$(lsof -nP +c 0 -iTCP -sTCP:LISTEN \
      | fzf --exit-0 --header-lines=1 --header="Select port" \
      | awk '{ n = split($9, a, ":"); print a[n] }')
    [[ -z $port ]] && return 1
  fi
  _devtools_validate_port "$port" || return 1
  pids=$(lsof -t -iTCP:"$port" -sTCP:LISTEN)
  [[ -z $pids ]] && { echo "Nothing listening on :$port"; return 1; }
  for pid in ${(f)pids}; do
    echo "PID $pid"
    ps -o command= -p "$pid"
    lsof -a -p "$pid" -d cwd -Fn | sed -n 's/^n/cwd: /p'
  done
}

# Tab-complete listening ports, with process name and PID
_listening_ports() {
  command -v lsof >/dev/null 2>&1 || return 0
  local -a entries
  entries=(${(f)"$(lsof -nP +c 0 -iTCP -sTCP:LISTEN 2>/dev/null \
    | awk 'NR>1 { n = split($9, a, ":"); p = a[n]; if (!seen[p]++) print p ":" $1 " (pid " $2 ")" }')"})
  _describe -t ports 'listening port' entries
}
