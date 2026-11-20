# zsh-devtools

Small zsh helpers for everyday dev work: jump between git worktrees, find and kill whatever is holding a port, and open your local dev server on a phone.

Built for **zsh on macOS** (it uses `ipconfig`, `route` and `pbpaste`).

## Requirements

- [fzf](https://github.com/junegunn/fzf), for the pickers: `brew install fzf`
- [qrencode](https://fukuchi.org/works/qrencode/) (optional), for QR codes: `brew install qrencode`

Dependencies are checked when a command needs them, not at shell startup.
`fzf` is only needed for pickers; explicit `whoport <port>` and `lanurl <port>`
work without it. Port commands require `lsof`; `pubip` requires `curl`.
Without `qrencode`, `qr` and `lanurl` still print their text successfully.

## Install

**oh-my-zsh**

```zsh
git clone https://github.com/sharpmist/zsh-devtools ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-devtools
```

Then add `zsh-devtools` to `plugins=(...)` in `~/.zshrc`.

**antidote**

```zsh
antidote bundle sharpmist/zsh-devtools
```

**zinit**

```zsh
zinit light sharpmist/zsh-devtools
```

**No plugin manager**

```zsh
git clone https://github.com/sharpmist/zsh-devtools
cd zsh-devtools
./install
```

`./install` copies the current checkout into `~/.local/share/zsh-devtools` and adds
one source line to `${ZDOTDIR:-$HOME}/.zshrc`. Re-running it updates the installed
files without duplicating that line. It requires no sudo and does not install dependencies.

To update this installation, run `git pull --ff-only && ./install` in the clone,
then `exec zsh`. For plugin-manager installations, use your manager's update command instead.

Source the plugin after `compinit` if you want Tab completion of ports.

## Commands

Run `devtools` (or its shorthand `zdev`) to list all available commands with descriptions.
Both also accept `-h` or `--help`.

### Git worktrees

| Command | What it does |
| --- | --- |
| `fwt` / `wt` | Pick a worktree of the current repo with fzf and `cd` into it |
| `dwt` / `dw` | Pick a worktree of the current repo and remove it |
| `gwl` | `git worktree list` |
| `gsc` | Print the current branch |

### Ports

| Command | What it does |
| --- | --- |
| `ports [filter]` | List listening TCP ports, e.g. `ports node` |
| `whoport [port]` | Show the full command and working directory of whatever listens on a port; with no port, pick one |
| `killport [port]` | Pick listening processes to kill (Tab to select several), with a preview of each command |

Tab after `killport`, `whoport` or `lanurl` completes the listening ports, with process name and PID.
Port arguments must be decimal numbers from 1 to 65535 (at most five digits).
Invalid arguments and cancelled or empty selections return a nonzero status without taking action.

### Network

| Command | What it does |
| --- | --- |
| `lanip` | This Mac's IP on the local network |
| `pubip` | Your public IP (via api.ipify.org) |
| `qr [text]` | Print text and its QR code; with no argument, use the clipboard |
| `lanurl [port]` | Print `http://<lan-ip>:<port>` and its QR code, to open your dev server on a phone. With no port, pick one that is reachable from other devices |

`lanurl` only lists ports bound to all interfaces. Start your dev server with `--host` (e.g. `pnpm start --host`) so other devices can reach it.

## Development

Run the tests with Bash and zsh installed:

```sh
bash -n install
bash -n tests/install.bash
for file in ./*.zsh tests/commands.zsh; do zsh -n "$file" || exit; done
zsh -f tests/commands.zsh
bash tests/install.bash
```

Command tests mock process, picker, clipboard, and network operations; they never
kill real processes or contact external services. Installer tests use a temporary
home directory. CI runs these checks on macOS and Linux (the plugin itself still
targets macOS).
