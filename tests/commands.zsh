#!/bin/zsh -f
# All process, picker, clipboard and network operations are mocked.
setopt errexit
cd "${0:A:h}/.."
source ./zsh-devtools.plugin.zsh

fail() { print -u2 -r -- "FAIL: $*"; exit 1; }
expect_failure() {
  local output
  if output=$("$@" 2>&1); then fail "expected failure: $*"; fi
}

reference=$(devtools)
[[ $reference == *killport* && $reference == *lanurl* ]] || fail 'help coverage'
[[ $(devtools -h) == $reference && $(devtools --help) == $reference ]] || fail 'help flags'
[[ $(eval zdev) == $reference ]] || fail 'alias'
expect_failure devtools invalid

for port in 1 80 0080 65535; do _devtools_validate_port "$port"; done
for port in '' 0 65536 -1 1.5 abc '80,443' '80-90' 999999999999999999999; do
  for cmd in whoport killport lanurl; do
    output=$("$cmd" "$port" 2>&1) && fail "$cmd accepted '$port'"
    [[ $output == *'invalid port'* ]] || fail "$cmd did not validate first"
  done
done
for cmd in whoport killport lanurl ports; do expect_failure "$cmd" 80 extra; done

# Missing dependencies fail only on invocation; help and sourcing stay quiet.
(
  PATH=/nonexistent
  [[ -z $(source ./zsh-devtools.plugin.zsh 2>&1) ]] || fail 'noisy startup'
  devtools >/dev/null
  output=$(ports 2>&1) && fail 'missing lsof accepted'
  [[ $output == *'missing dependency: lsof'* ]] || fail 'dependency diagnostic'
  expect_failure _pick_worktree test
  expect_failure qr
  expect_failure pubip
  expect_failure lanip
  [[ $(qr 'plain text') == 'plain text' ]] || fail 'optional qrencode'
)

lsof() {
  if [[ $1 == -t ]]; then print 4242; return; fi
  if [[ $1 == -a ]]; then print 'n/tmp/project'; return; fi
  print 'COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME'
  print 'node 4242 user 20u IPv4 0x0 0t0 TCP *:5173 (LISTEN)'
}
ps() { print 'node server.js'; }
fzf() {
  case ${picker_mode:-select} in
    cancel) return 130 ;;
    empty) return 0 ;;
    *) awk 'NR==2' ;;
  esac
}
# Never signal an actual process.
kill() { print -r -- "$*"; }
route() { print 'interface: en0'; }
ipconfig() { print '192.0.2.10'; }
curl() { print '198.51.100.10'; }
pbpaste() { print 'clipboard text'; }
qrencode() { return 0; }

[[ $(ports node) == *4242* ]] || fail 'ports listing'
[[ $(whoport 5173) == *'PID 4242'* ]] || fail 'explicit whoport'
[[ $(whoport) == *'/tmp/project'* ]] || fail 'picker whoport'
[[ $(killport 5173) == '-- 4242' ]] || fail 'kill selection'
[[ $(lanurl 5173) == 'http://192.0.2.10:5173' ]] || fail 'explicit LAN URL'
[[ $(lanurl) == 'http://192.0.2.10:5173' ]] || fail 'picker LAN URL'
[[ $(pubip) == '198.51.100.10' ]] || fail 'public IP'
[[ $(qr) == 'clipboard text' ]] || fail 'clipboard'

for picker_mode in cancel empty; do
  expect_failure whoport
  expect_failure killport
  expect_failure lanurl
done
unset picker_mode

# Explicit ports do not depend on fzf; interactive calls do.
(
  sed_binary=$(command -v sed)
  awk_binary=$(command -v awk)
  sed() { "$sed_binary" "$@"; }
  awk() { "$awk_binary" "$@"; }
  unfunction fzf
  PATH=/nonexistent
  [[ $(whoport 5173) == *'PID 4242'* ]] || fail 'whoport without fzf'
  [[ $(lanurl 5173) == 'http://192.0.2.10:5173' ]] || fail 'lanurl without fzf'
  for cmd in whoport killport lanurl; do
    output=$("$cmd" 2>&1) && fail "$cmd accepted missing fzf"
    [[ $output == *'missing dependency: fzf'* ]] || fail 'missing fzf diagnostic'
  done
)

# Worktree paths with spaces and picker cancellation, without touching git state.
(
  original=$PWD
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT
  mkdir "$tmp/tree with spaces"
  git() {
    if [[ $1 == worktree && $2 == list ]]; then
      print -r -- "worktree $tmp/tree with spaces"
      print 'branch refs/heads/test'
    else
      print -r -- "$*"
    fi
  }
  fzf() { awk 'NR==1'; }
  fwt
  [[ $PWD == "$tmp/tree with spaces" ]] || fail 'worktree path with spaces'
  cd "$original"
  [[ $(dwt) == *"worktree remove $tmp/tree with spaces"* ]] || fail 'worktree removal'
  fzf() { return 130; }
  expect_failure fwt
  expect_failure dwt
  [[ $PWD == $original ]] || fail 'cancel changed directory'
)

curl() { return 7; }
expect_failure pubip
ipconfig() { return 1; }
expect_failure lanurl 5173
route() { return 1; }
expect_failure lanip
lsof() { return 1; }
expect_failure whoport 5173
expect_failure killport
expect_failure lanurl

print 'PASS: command validation, dependencies, mocked operations, and cancellation'
