# Kill listening process(es); port is optional. TAB to multi-select.
killport() {
  lsof -nP +c 0 -iTCP${1:+:$1} -sTCP:LISTEN \
  | fzf -m --exit-0 --header-lines=1 \
        --header="Select process(es) to kill${1:+ on port $1}" \
        --preview 'ps -o command= -p {2}; lsof -a -p {2} -d cwd -Fn | sed -n "s/^n/cwd: /p"' \
        --preview-window=down,3,wrap \
  | awk '{print $2}' | sort -u \
  | xargs -r kill
}

# List listening TCP ports, optionally filtered: ports | ports node
ports() {
  lsof -nP +c 0 -iTCP -sTCP:LISTEN | awk -v q="$1" 'NR==1 || tolower($0) ~ tolower(q)'
}

# Full command line + working directory of whatever listens on a port.
# whoport 5173, or run whoport with no port to pick one with fzf
whoport() {
  local port=$1 pids pid
  if [[ -z $port ]]; then
    port=$(lsof -nP +c 0 -iTCP -sTCP:LISTEN \
      | fzf --exit-0 --header-lines=1 --header="Select port" \
      | awk '{ n = split($9, a, ":"); print a[n] }')
    [[ -z $port ]] && return 1
  fi
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
  local -a entries
  entries=(${(f)"$(lsof -nP +c 0 -iTCP -sTCP:LISTEN 2>/dev/null \
    | awk 'NR>1 { n = split($9, a, ":"); p = a[n]; if (!seen[p]++) print p ":" $1 " (pid " $2 ")" }')"})
  _describe -t ports 'listening port' entries
}
