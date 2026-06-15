# claude-hpc-config

Shared Claude Code agents and skills for Weecology ML experiments on HiPerGator.
Covers job sizing, submission, monitoring, and experiment logging for airborne
detection projects (trees, birds, etc.).

## What's here

```
agents/
  launch.md      # sizes and submits Slurm jobs; reads ledger for past resource use
  log.md         # monitors runs, records outcomes; read-only on the cluster
  ledger.md      # steward of experiments/ledger.jsonl
  analytics.md   # computes project metrics after a run — fork this per project
skills/
  ledger-format/ # shared JSONL schema used by all agents
CLAUDE.md        # copy into each project repo root
GETTING_STARTED.md
install.sh
```

## Setup (once per HiPerGator account)

```bash
git clone https://github.com/weecology/claude-hpc-config
cd claude-hpc-config
bash install.sh
```

This copies the agents and skill to `~/.claude/`, making them available in every
Claude Code session on HiPerGator.

## Per-project setup

In each project repo:

```bash
# 1. Copy the shared config files into the repo root
cp /path/to/claude-hpc-config/CLAUDE.md .
cp /path/to/claude-hpc-config/GETTING_STARTED.md .

# 2. Create the ledger
mkdir -p experiments
touch experiments/ledger.jsonl
git add experiments/ledger.jsonl

# 3. Fork the analytics agent for this project's metrics
mkdir -p .claude/agents
cp /path/to/claude-hpc-config/agents/analytics.md .claude/agents/
# edit .claude/agents/analytics.md for this project
```

Project-level agents in `.claude/agents/` override the user-level ones in
`~/.claude/agents/` when names collide, so the analytics fork is picked up
automatically without touching the shared install.

## Updating

```bash
cd claude-hpc-config
git pull
bash install.sh   # re-copies to ~/.claude/
```

Project-level forks of `analytics.md` are unaffected — only the user-level
copy in `~/.claude/agents/` is updated.

## How the agents interact

```
User request
    │
    ▼
launch agent ──reads──▶ ledger (past resource use)
    │                        ▲
    │ sbatch                 │ append / patch
    ▼                        │
Slurm job ◀── monitors ── log agent
                             │
                        analytics agent (on completion)
```

The ledger (`experiments/ledger.jsonl`) is the shared state: `launch` writes
the intent, `log` writes the outcome, `analytics` writes the result. All three
layers live in the same JSONL line, keyed by `run_id`.

## Customizing for a new project

The only file that should be edited per project is `analytics.md`. Everything
else (launch, log, ledger, ledger-format) is project-agnostic. The `CLAUDE.md`
in the project root can be extended with project-specific notes below the
shared content.
