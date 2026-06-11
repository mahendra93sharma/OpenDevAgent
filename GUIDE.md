# MAI — User Guide

MAI is an autonomous Claude agent you point at a folder with one mission prompt.
It works alone — no questions, no waiting for you — until the goal is done,
keeps your Mac awake while running, and is OS-jailed so it can never damage
anything outside the folder you activate it in.

---

## 1. Quick start (any project folder)

`mai` is installed system-wide (`~/.local/bin/mai`). Use it from anywhere:

```sh
cd ~/AnyProject
mai . "Refactor the API layer, add tests, make sure all tests pass"
```

`mai <folder> "<mission>"` — that's the whole interface.

- `.` — activate in current folder (it becomes the agent's admin zone)
- `mai my-task "..."` — creates `./my-task/` and jails the agent there
- `mai ~/Missions/scraper` — no prompt = reads `~/Missions/scraper/MISSION.md`

Run overnight, detached from the terminal:

```sh
nohup mai ~/AnyProject "mission..." > /dev/null 2>&1 &
```

Watch progress live:

```sh
tail -f <folder>/.agent/logs/run-*.log
```

---

## 2. The permission model (what it can and cannot do)

The folder you activate MAI in = its territory. Enforced by the macOS kernel
(`sandbox-exec`), not by trusting the model.

| Where | Read | Create/Write | Delete | Execute |
|---|---|---|---|---|
| **Inside activation folder** | ✅ | ✅ | ✅ | ✅ — full admin |
| **Outside the folder** | ✅ | ❌ blocked | ❌ blocked | ✅ (read-only tools) |
| **Network / outside services** | ✅ APIs, web, git fetch, curl — all open | | | |

So the agent can *use* the rest of your system as a resource — read other
projects' code, call APIs, fetch docs, query services — but any attempt to
write, overwrite, or delete outside its folder fails with
`Operation not permitted`. Even `rm -rf /` from inside the agent would bounce
off the kernel.

> Exception: Claude's own state dirs (`~/.claude`, caches, temp) stay writable —
> the agent needs those to function.

---

## 3. Subagents (the agent builds its own team)

MAI can spawn **multiple subagents** to split the work — this is built in, no
setup needed. The main agent decides when to delegate: parallel research,
splitting a big refactor across files, one subagent writing code while another
reviews it.

Two important properties:

1. **Subagents inherit the jail.** They are child processes of the sandboxed
   agent, so the same rules apply — admin inside the folder, read-only outside.
   No subagent can escape.
2. **You can ask for them in the mission.** Example:

```sh
mai ./research "Research the top 5 vector databases. Spawn parallel subagents,
one per database, to gather benchmarks and pricing. Then merge everything into
a single comparison report.md with a final recommendation."
```

---

## 4. Lifecycle of a run

1. You launch: `mai <folder> "<mission>"`.
2. Mission saved to `<folder>/MISSION.md`; Mac sleep disabled (`caffeinate`).
3. Agent works autonomously inside the jail — decides, codes, verifies,
   spawns subagents as needed. Never asks you anything.
4. When the goal is **verifiably achieved**, the agent writes
   `<folder>/DONE.md` — what it did, how it verified, where results are.
5. If the session ends *without* `DONE.md`, MAI auto-resumes it (up to
   `MAX_RESUMES` times) until the goal is reached.
6. Process exits → caffeinate releases → Mac can sleep again.

### Files MAI leaves in the folder

```
<folder>/
├── MISSION.md           # your prompt (kept for resumes + audit)
├── DONE.md              # final report — appears only when goal achieved
├── ...results...        # whatever the mission produced
└── .agent/
    ├── profile.sb       # the rendered jail profile for this run
    └── logs/run-*.log   # full transcript of every run/resume
```

---

## 5. Tuning

```sh
MODEL=sonnet MAX_RESUMES=20 MAX_BUDGET_USD=10 mai ./task "mission"
```

| Var | Default | Meaning |
|---|---|---|
| `MODEL` | `fable` | `fable` (smartest) / `opus` / `sonnet` / `haiku` (cheapest) |
| `MAX_RESUMES` | `10` | Auto-resume attempts if it stops before the goal |
| `MAX_BUDGET_USD` | `25` | Hard spend cap per run — agent stops at this limit |

---

## 6. Managing running agents

```sh
# see running agents
pgrep -fl "sandbox-exec -f"

# stop one agent (use its folder path)
pkill -f "<folder>/.agent/profile.sb"

# run several agents in parallel — each has its own jail, logs, budget
mai ~/jobs/scraper "..." &
mai ~/jobs/report  "..." &
```

---

## 7. ERA — the mission architect

Don't want to write a structured mission yourself? `era` (also system-wide)
turns a rough prompt into a proper mission:

```sh
cd ~/AnyProject
era . "make my api faster"      # rough idea in → mission drafted → MAI auto-starts
```

ERA inspects the folder, then writes:

- `MISSION.md` — goal, context, concrete tasks (with subagent parallelism
  marked), constraints, **verifiable** success checks, exact deliverables
- `DONE.template.md` — acceptance checklist MAI's final `DONE.md` must satisfy

…then **automatically hands off to `mai <folder>`** to execute the mission.
Want to review/edit `MISSION.md` first? Run `ERA_AUTO_MAI=0 era ...` to draft
only, then launch `mai <folder>` yourself whenever ready — `mai` always works
standalone. ERA uses `sonnet` by default (cheap, fast) — override with
`MODEL=fable era ...`.

---

## 8. Writing good missions

The agent only stops when the goal is **verifiable** — so state the end
condition explicitly:

- ❌ "improve the tests" — fuzzy, agent can't prove done
- ✅ "raise test coverage above 80% and make `npm test` pass; put the coverage
  report in coverage.md"

Good pattern: `[do X] + [verify by Y] + [deliver result in file Z]`.
Mention subagents explicitly when you want parallel work.

---

## 9. Safety notes

- Activate MAI **only in folders you're fine being fully rewritten** — inside
  its territory it is admin by design.
- Network is open: the agent can call external services. Budget cap
  (`MAX_BUDGET_USD`) bounds API spend per run.
- Everything is logged in `.agent/logs/` — full audit trail of every action.
