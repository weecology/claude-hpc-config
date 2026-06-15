---
name: ledger-format
description: Schema and append/patch rules for experiments/ledger.jsonl. Use whenever writing a new run line or patching an outcome.
---

# Ledger format

One JSON object per line. Append-only; patch by `run_id`.

## Schema

**Written by `launch` at submission:**
```
run_id        unique string (ISO timestamp + short hash)
created_at    ISO 8601
reason        2–3 sentences, required
git_sha       commit hash
config_hash   hash of resolved config
task          "tree" | "bird" | ...
model         backbone / architecture
slurm_job_id  string
requested     { partition, gpu_type, gpu_count, cpus, mem_gb, walltime_h }
comet         { workspace, project, experiment_key }
status        "submitted"
```

**Patched by `log` on completion:**
```
status        "completed" | "failed" | "timeout" | "oom"
exit_code     int
elapsed       seconds
actual        { peak_cpu_mem_gb, peak_gpu_mem_gb, gpu_util_mean }
oom           bool
timeout       bool
```

**Patched by `analytics`:**
```
result_summary  2–3 sentences
metric          { name, value, prior_best, delta }
```

## Rules

- Corrections append a new line referencing the original `run_id` — never edit history.
- `requested` vs `actual` drives launch sizing. Keep both.
- Comet URL: `comet.com/{workspace}/{project}/{experiment_key}`.
