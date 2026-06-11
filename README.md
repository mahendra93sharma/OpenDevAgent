# OpenDevAgent

**Autonomous Claude agents for your Mac.** Give one prompt — the agent works
alone until the goal is verifiably done. No questions, no babysitting. Your Mac
stays awake while it works, and the agent is OS-jailed to one folder so it can
never damage the rest of your system.

Two commands:

| Command | Role |
|---|---|
| `era` | **Mission architect** — turns your rough idea into a structured, verifiable `MISSION.md` + acceptance checklist |
| `mai` | **Executor** — runs the mission autonomously until done, spawning parallel subagents when useful |

```sh
cd ~/my-project
era . "add unit tests and get coverage above 80%"   # rough idea → structured mission
mai .                                               # executes until verifiably done
```

That's it. Come back to `DONE.md` — what was done, how it was verified, where
the results are.

## Requirements

- **macOS** (the jail uses `sandbox-exec`, keep-awake uses `caffeinate` — both ship with macOS)
- **[Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)**, authenticated:
  ```sh
  npm install -g @anthropic-ai/claude-code
  claude   # interactive login once
  ```

## Install

```sh
git clone https://github.com/<you>/OpenDevAgent.git
cd OpenDevAgent
./install.sh
```

The installer symlinks `mai` and `era` into `~/.local/bin` and ensures it's on
your PATH. Remove with `./uninstall.sh`.

## Why it's safe to leave running overnight

The folder you activate the agent in is its **territory** — full admin inside.
Everything outside is **read-only**, enforced by the macOS kernel
(`sandbox-exec`), not by trusting the model:

| Where | Read | Write/Delete |
|---|---|---|
| Inside the activation folder | ✅ | ✅ full admin |
| Anywhere else on disk | ✅ | ❌ `Operation not permitted` |
| Network (APIs, web, git) | ✅ open | — |

Plus a hard per-run spend cap (`MAX_BUDGET_USD`, default $25) and a full audit
log of every action in `<folder>/.agent/logs/`.

## How it works

1. `era` inspects your folder and writes `MISSION.md` (goal, tasks, constraints,
   **verifiable** success checks, deliverables) and `DONE.template.md`
   (acceptance checklist).
2. `mai` launches Claude headless inside `caffeinate` (Mac can't sleep) +
   `sandbox-exec` (write-jail), with permission prompts disabled — the agent
   decides everything itself, and spawns parallel subagents for big tasks
   (subagents inherit the jail).
3. The agent works until the goal is **verifiably achieved**, then writes
   `DONE.md` proving it (checks run, outputs shown).
4. If the session dies early, `mai` auto-resumes it — up to `MAX_RESUMES`
   times — until `DONE.md` exists.

## Tuning

```sh
MODEL=sonnet MAX_RESUMES=20 MAX_BUDGET_USD=10 mai ./task "mission"
```

| Var | Default | Meaning |
|---|---|---|
| `MODEL` | `fable` (mai) / `sonnet` (era) | Claude model alias |
| `MAX_RESUMES` | `10` | Auto-resume attempts before giving up |
| `MAX_BUDGET_USD` | `25` | Hard API spend cap per run |

## Examples

See [`examples/`](examples/) for ready-to-run missions:

```sh
mai ./btc-tracker "$(cat examples/btc-tracker.md)"
```

Full manual: [GUIDE.md](GUIDE.md).

## FAQ

**Does my Mac need to stay on?** Yes — agents run locally. `mai` keeps it awake
(`caffeinate`) for the duration of the run and releases when done. Lid must stay
open (or Mac on AC power with an external display) for `caffeinate` to prevent sleep.

**Can it really not delete my files?** Outside its folder — no. The kernel
rejects every write/delete syscall. Try it yourself:
`sandbox-exec -f <folder>/.agent/profile.sb touch ~/Desktop/x` → `Operation not permitted`.

**What does it cost?** Whatever the underlying Claude API/subscription usage
costs, hard-capped per run by `MAX_BUDGET_USD`.

**Linux/Windows?** Not yet — the jail is built on macOS `sandbox-exec`.
Contributions welcome (Linux: bubblewrap/firejail port).

## License

MIT — see [LICENSE](LICENSE).
