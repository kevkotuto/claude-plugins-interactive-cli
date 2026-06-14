# interactive-cli — a Claude Code plugin

Let Claude Code **drive interactive command-line programs by itself** — prompts that wait
for input, REPLs, arrow-key menus, y/n confirmations — instead of asking you to type.

It runs the program in a detached **tmux** session, **reads** the screen to see each
prompt, and **sends** the answer. Perfect for `gcloud auth login`, `eas build`/`expo`
prompts, `prisma migrate dev`, `npm create` scaffolders, deploy scripts, and anything
that pauses for an answer — especially when you're away from the keyboard.

## Requirements

`tmux` installed (`brew install tmux` / `apt install tmux`).

## Install

In Claude Code:

```
/plugin marketplace add kevkotuto/claude-plugins-interactive-cli
/plugin install interactive-cli@interactive-cli-marketplace
```

(Replace `kevkotuto/...` with wherever you host this repo.)

Or try it locally without publishing:

```
/plugin marketplace add /absolute/path/to/claude-plugins-interactive-cli
/plugin install interactive-cli@interactive-cli-marketplace
```

## How it works

Once installed, the `interactive-cli` skill activates automatically when Claude hits a
command that would block on input. Under the hood it uses `scripts/it.sh`:

```
it.sh start <name> <command...>   # launch in a detached tmux session
it.sh wait  <name> <regex> [secs] # block until a prompt appears
it.sh read  <name> [lines]        # read the screen
it.sh send  <name> <text...>      # type text + Enter
it.sh key   <name> <keys...>      # raw keys: Enter, C-c, Up, Down, Tab...
it.sh alive <name> | kill <name> | list
```

## Safety

- Claude always reads a prompt before answering it.
- For secrets it doesn't have (passwords, OTP/2FA), it stops and asks you.
- For destructive/outward-facing confirmations, normal approval rules apply.

## License

MIT
