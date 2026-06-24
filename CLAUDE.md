# ML experiments with Claude on HiPerGator

Five subagents handle the operational overhead of running airborne-detection jobs
(tree, bird) so we spend time on science, not Slurm.

## Agents

- `launch` — reads the ledger for sizing, sanity-checks configs, submits. Auto-submits reruns and small jobs; asks first for large ones; always asks before `scancel`.
- `log` — read-only monitor; catches early errors, checks liveness, records actual resource use.
- `utilization` — compares requested vs actual resources (Slurm + Comet), finds similar past runs, and advises sizing with gentle questions — never submits or edits jobs.
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
ground truth). The `utilization` agent interprets those numbers into requested-vs-actual
ratios and queue-friendly sizing advice. When Slurm and Comet disagree at end-of-run,
trust Slurm for failure flags.

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

- `log` and `utilization` never submit. No agent deletes data or changes account settings without approval.
- Every submitted run gets a ledger line before it counts as launched.

## Coding Philosophy

### Code Style
- **Pythonic**: Idiomatic Python, PEP 8
- **Concise**: Favor brevity and clarity over verbosity
- **Minimal**: Simplest solution that works; avoid over-engineering
- **Functional**: Prefer functional patterns where appropriate

### Error Handling
- **Fail Fast**: Let code fail quickly and visibly
- **Minimal Try/Except**: Avoid blocks that mask underlying issues
- **No Silent Failures**: Don't catch exceptions unless you can meaningfully handle them. Never swallow I/O errors by returning blank/zero data — a missing or unreadable file is a real problem that must surface as a hard error.

### Testing
- Write only essential tests that catch critical functionality
- Prefer integration tests that test real workflows over unit tests for trivial operations

### What TO Do
- Use list/dict comprehensions instead of explicit loops when clearer
- Use type hints for function signatures
- Write docstrings for public functions and classes
- Use `pathlib` instead of `os.path` for file operations
- Prefer f-strings over `.format()` or `%` formatting
- Use context managers for resource management
- Handle edge cases with early returns rather than nested conditions

### What NOT To Do
- Don't wrap every operation in try/except "just in case"
- Don't add unnecessary abstraction layers
- Don't catch broad exceptions (`Exception`, `BaseException`) unless absolutely necessary
- Don't suppress errors with `pass` in except blocks
- Don't add configuration options for things that don't need to be configurable
- Avoid over-use of argparse and CLI for simple scripts

### File I/O
```python
# Good: let operations fail fast and explicitly
def process_file(path):
    with open(path) as f:        # FileNotFoundError bubbles up clearly
        return json.load(f)      # JSONDecodeError bubbles up clearly

# OK: explicit handling of a legitimately optional file
def load_optional_config(path):
    try:
        with open(path) as f:
            return json.load(f)
    except FileNotFoundError:
        return None
```

### Comments
- Document complex algorithms, non-obvious constraints, or workarounds for external library bugs.
- Don't document obvious operations, standard library usage, or self-explanatory code.
