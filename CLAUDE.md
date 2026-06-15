# ML experiments with Claude on HiPerGator

Four subagents handle the operational overhead of running airborne-detection jobs
(tree, bird) so we spend time on science, not Slurm.

## Agents

- `launch` — reads the ledger for sizing, sanity-checks configs, submits. Auto-submits reruns and small jobs; asks first for large ones; always asks before `scancel`.
- `log` — read-only monitor; catches early errors, checks liveness, records actual resource use.
- `ledger` — steward of `experiments/ledger.jsonl`; enforces the reason field and Comet/git links.
- `analytics` — computes project metrics after a run and compares to the prior best.

Definitions: `.claude/agents/`. Shared procedures: `.claude/skills/`.

## The ledger

`experiments/ledger.jsonl` — one line per run, append-only, committed to git.

| Layer | Tool | What lives there |
|---|---|---|
| Code state | git | `git_sha` in every ledger line |
| Why + resources + outcome | ledger (JSONL) | reason, requested, actual, exit |
| Metric curves | Comet | ledger stores keys only, never curves |

Schema: `.claude/skills/ledger-format/SKILL.md`.

## Comet

Workspace: `bw4sz`. The `launch` agent reads past peak GPU memory from Comet to size
new runs. The `log` agent merges Comet (GPU utilization) with `sacct`/`seff` (failure
ground truth). When they disagree at end-of-run, trust Slurm for failure flags.

## HiPerGator

- Account: `ewhite`
- Logs: `/home/b.weinstein/logs/`
- Mail: `ben.weinstein@weecology.org`
- GPU tiers:
  - Default (fine-tuning, inference): `--gpus=1` on the default partition
  - Multi-GPU training: `--partition=hpg-turin --gpus=3 --ntasks-per-node=3`
  - Do **not** request `H200`/`B200` unless explicitly needed
- Environment: `source /blue/ewhite/b.weinstein/src/<project>/.venv/bin/activate`
  or `uv run --group <group>` (see sample scripts in `.claude/skills/slurm-templates/`)

## Tunnel / interactive work

See `GETTING_STARTED.md`. For an interactive GPU node, ask the `launch` agent.

## Hard rules

- `log` never submits. No agent deletes data or changes account settings without approval.
- Every submitted run gets a ledger line before it counts as launched.
