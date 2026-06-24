---
name: utilization-analysis
description: Procedures for comparing Slurm requested vs actual resource use, Comet GPU metrics, and similar-run ledger queries. Use when advising job sizing or reporting utilization.
---

# Utilization analysis

Read-only analysis to reduce queue oversubscription from inflated `--mem`, GPU tier,
and walltime requests.

## Ledger fields

From `ledger-format`:

```
requested  { partition, gpu_type, gpu_count, cpus, mem_gb, walltime_h }
actual     { peak_cpu_mem_gb, peak_gpu_mem_gb, gpu_util_mean }
elapsed    seconds
oom        bool
timeout    bool
```

Utilization only makes sense when `status` is terminal (`completed`, `failed`, `oom`,
`timeout`) and `actual` or fresh Slurm/Comet data exists.

## Slurm harvest

On HiPerGator login node (job must have finished):

```bash
# Compact outcome + memory
sacct -j <job_id> --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocTRES -P

# Human-readable efficiency summary
seff <job_id>
```

Interpretation:

- **MaxRSS** → peak CPU RAM (convert to GB). Compare to `requested.mem_gb`.
- **ReqMem** / **AllocTRES** → what Slurm reserved (sanity-check against ledger
  `requested`).
- **Elapsed** → compare to `requested.walltime_h × 3600`.
- **State / ExitCode** → if OOM or TIMEOUT, do not recommend tightening that dimension.

`seff` reports "Memory Utilized" vs "Memory Efficiency" — use these for the CPU RAM
ratio when ledger `actual.peak_cpu_mem_gb` is missing.

## Comet harvest

When ledger has `comet.experiment_key` (workspace usually `bw4sz`):

1. Resolve experiment via Comet API or `comet_ml` Python client in the project venv.
2. Pull system metrics logged during training:
   - **Peak GPU memory** (GB) — primary signal for `--mem` on GPU jobs and for whether
     a smaller GPU tier would suffice.
   - **Mean GPU utilization** (%) — low sustained util may mean overscaled GPU count,
     I/O bound workload, or under-filled batch; say which hypotheses fit the `reason`.

If no Comet experiment exists, use Slurm MaxRSS for CPU RAM only; note that GPU memory
and compute util are unavailable without Comet or nvidia-smi logs.

## Utilization ratios

```
cpu_mem_util     = peak_cpu_mem_gb / requested.mem_gb
gpu_mem_util     = peak_gpu_mem_gb / gpu_vram_gb(gpu_type)   # per GPU, or × gpu_count for total
walltime_util    = elapsed_sec / (requested.walltime_h * 3600)
gpu_compute_util = gpu_util_mean / 100                       # already 0–1 if stored as percent
```

**GPU VRAM reference** (single device, approximate):

| gpu_type (ledger) | GB |
|-------------------|-----|
| L4, L40S          | 24  |
| A100              | 40  |
| A100-80GB         | 80  |
| H100              | 80  |

If `gpu_type` is unknown, infer from partition/account notes or ask — do not guess VRAM.

**Headroom policy** (for suggestions only):

- Target **~1.25–1.5×** peak for CPU `--mem` when peers show stable peaks and no OOM.
- Target **~1.1–1.25×** peak GPU memory vs device capacity when choosing GPU tier.
- Walltime: suggest `elapsed × 1.3–1.5` rounded up to sensible Slurm units, unless
  the run hit TIMEOUT.

**Over-allocation flags** (advisory, not automatic cuts):

| Signal | Typical threshold | Likely issue |
|--------|-------------------|--------------|
| cpu_mem_util | < 0.4 sustained across peers | `--mem` too high |
| gpu_mem_util | < 0.35 with no OOM | GPU tier or `--mem` too high |
| gpu_compute_util | < 0.25 mean | I/O, small batch, or unnecessary multi-GPU |
| walltime_util | < 0.25 | walltime inflated → queue priority cost |

Always pair flags with questions — peaks differ when image size, workers, or caching
change even if the script path is identical.

## Similar-run query

Scan `experiments/ledger.jsonl` (newest first):

1. Filter `task` (+ `model` when known).
2. Keep `status == completed` unless diagnosing failures.
3. Require non-null `actual.peak_gpu_mem_gb` or harvestable `slurm_job_id`.
4. Rank by: same `config_hash` > same `gpu_count` > keyword overlap in `reason`.
5. Return top 3–5 peers with their utilization ratios, not just raw peaks.

Example user question mapping:

- "Similar to this bird run" → match `task=bird`, same backbone, compare proposed
  `requested` to peer median peaks.
- "Last five tree jobs GPU memory" → filter `task=tree`, take last 5 completed, list
  peak GPU mem and cpu_mem_util.

## Advisory tone

- Lead with data, then questions, then optional tighter `requested` sketch.
- Confidence: **high** (≥3 similar peers, tight config match), **medium** (same task/model,
  config drift), **guess** (no peers — say so).
- Never auto-edit sbatch; hand sketches to `launch`.
- If utilization is healthy (ratios 0.5–0.8 with no OOM history), say the request is
  reasonable — do not always push downward.

## Cross-checks

- OOM run → recommend *more* of the binding resource, not less.
- TIMEOUT → recommend more walltime or faster config, not less.
- Failed non-OOM → utilization advice is secondary; mention exit state first.
- Multi-GPU (`hpg-turin`, `gpu_count > 1`): compare per-GPU peaks; one idle GPU is a
  strong signal to question multi-GPU need.
