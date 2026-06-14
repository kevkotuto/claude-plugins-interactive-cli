---
name: interactive-cli
description: Drive interactive command-line programs yourself (prompts that wait for input, REPLs, arrow-key menus, confirmations) via a tmux helper, instead of asking the user to type. Use whenever a command would block on stdin — e.g. `gcloud auth login`, `eas build`/`expo` prompts, `prisma migrate dev` (asks for a migration name), `npm create`/scaffolders, y/n confirmations, or any tool that pauses for an answer. Especially useful when the user is away from the keyboard.
---

# Interactive CLI driver

Normal shell tool calls **block** on interactive prompts: the program waits for stdin you can't provide, and you're forced to ask the user to type. This skill lets you run the program in a detached **tmux** session, **read** the screen to see the prompt, and **send** the answer yourself — driving the whole flow end to end.

## Prerequisites

`tmux` must be installed (`which tmux`). On macOS: `brew install tmux`. On Debian/Ubuntu: `apt install tmux`. The helper uses an isolated tmux server (`-L claude-it`) so it never touches the user's own tmux sessions.

The helper lives next to this file: `scripts/it.sh` (relative to this skill's directory). Set `IT="$(dirname THIS_SKILL)/scripts/it.sh"` or just call it by absolute path.

## Commands

```
it.sh start <name> <command...>   # launch <command> in a detached tmux session
it.sh wait  <name> <regex> [secs] # block until <regex> appears on screen (default 30s); exit 1 on timeout/early-exit
it.sh read  <name> [lines]        # print the last [lines] of the pane (default 60)
it.sh send  <name> <text...>      # type <text> then press Enter
it.sh type  <name> <text...>      # type <text> WITHOUT Enter
it.sh key   <name> <keys...>      # send raw tmux keys: Enter, C-c, Up, Down, Space, Tab, BSpace...
it.sh alive <name>                # prints "running" / "exited"; exit 1 if not running
it.sh kill  <name>                # kill the session
it.sh list                        # list live sessions
```

## The loop

1. `start` the command.
2. `wait` for the first prompt's text (a regex matching what the program prints).
3. `read` the pane to **confirm the exact prompt** before answering.
4. `send` the answer (or `key` for menus).
5. Repeat `wait` → `read` → `send` for each subsequent prompt.
6. After the program finishes, `read` once more for the final output (the pane is kept alive via `remain-on-exit`, so the last lines aren't lost).
7. `kill` the session.

## Examples

**A scripted Q&A flow:**
```bash
IT=~/.claude/skills/interactive-cli/scripts/it.sh
$IT start deploy "./deploy.sh"
$IT wait deploy "Environment" 10
$IT read deploy            # confirm it's asking what you think
$IT send deploy "production"
$IT wait deploy "Confirm.*y/n" 10
$IT send deploy "y"
$IT wait deploy "Done|Failed" 120
$IT read deploy            # final result
$IT kill deploy
```

**Arrow-key selection menu** (e.g. `npm create`, expo prompts): read the menu, then move + select.
```bash
$IT key scaffold Down      # move down one item
$IT key scaffold Down
$IT key scaffold Enter     # select
```

**Cancel a hung program:** `$IT key <name> C-c`.

## Rules

- **Always `read` before `send`** to verify the actual prompt — don't answer blind.
- Use `wait` with a regex tied to the prompt text so you act exactly when the program is ready, not on a fixed sleep.
- If a prompt asks for a **secret you don't have** (password, OTP/2FA code, API key not in your context or memory), stop and ask the user — don't guess.
- For destructive or outward-facing confirmations (deploys, deletions, `git push`), apply normal judgment: confirm with the user first unless already authorized.
- Use distinct `<name>` values if running several interactive programs at once.
