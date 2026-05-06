---
name: HNAICC_aip_submit
description: Use when the user mentions creating or submitting jobs on the HNAICC cluster - writes .aip scripts with #CSUB parameters, submits via csub, and handles batch submissions. Do NOT use for checking job status (use HNAICC_job_monitor) or log analysis.
version: 2.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [hnaicc, hpc, cluster, lsf, job-scheduling, aip, csub, batch-submission]
    related_skills: [HNAICC_ssh, HNAICC_project_setup, HNAICC_env_setup, HNAICC_job_monitor, HNAICC_job_logs]
---

# HNAICC AIP Submit — Job Script Creation & Submission

## Checklist

1. **SSH credentials configured** — verify `login_www` works (see HNAICC_ssh skill)
2. **Project directory ready** — working directory set up (see HNAICC_project_setup skill)
3. **Environment ready** — conda or module environment available (see HNAICC_env_setup skill)
4. **Load AIP environment** — `source /opt/skyformai/etc/aip.sh` in every session
5. **Name the job** — set `-A` (project-level) and `-J` (job-level) names
6. **Select CPU count** — based on memory needs (see CPU table below)
7. **Write `.aip` script** — with correct `#CSUB` directives
8. **Submit and verify** — `csub < job.aip` then `cjobs` to confirm

**Don't use for:** SSH setup (use `HNAICC_ssh`), checking job status (use `HNAICC_job_monitor`), or analyzing logs (use `HNAICC_job_logs`).

## Critical Rule: Load AIP Environment

Every SSH session MUST load the AIP environment before using cluster commands:

```bash
source /opt/skyformai/etc/aip.sh
```

Without this, `csub` fails with `Authentication failed` (exit code may still be 0). Add to `~/.bashrc` for auto-loading.

---

## Step 1: Name the Job (-A and -J)

| Parameter | Purpose | Convention | Example |
|-----------|---------|------------|---------|
| `-A` | **Project-level** — shared across all jobs in the same pipeline | `<project>_<analysis_type>` | `WGS_variant_calling` |
| `-J` | **Job-level** — unique per submission, visible in `cjobs` | `<A_name>_<sample_or_step>` | `WGS_vc_SAMPLE01` |

Rules: alphanumeric + underscore only; `-J` must be unique and human-readable.

---

## Step 2: Select CPU Count (-n)

On the c01 queue, **memory is tied to core count at 11GB/core**:

| -n | Memory | Suitable For |
|----|--------|-------------|
| 1 | 11GB | Small scripts, testing |
| 2 | 22GB | Lightweight tools |
| 4 | 44GB | Single-sample alignment |
| 8 | 88GB | Multi-sample QC |
| 16 | 176GB | **Default** — RNA-seq, variant calling |
| 32 | 352GB | Large assemblies |
| 44 | 484GB | Near-full-node |
| 64 | 704GB | Very large assemblies |
| 88 | 968GB | Full-node exclusive |

Decision flow: (1) Estimate memory need → (2) `ceil(needed / 11GB)` → (3) Round up to nearest allowed count → (4) If tool uses parallelism, request more cores.

Other queues: see `HNAICC_job_monitor` skill for full queue specs.

---

## Step 3: Write AIP Job Script

### Standard Structure

```bash
#!/bin/bash
#CSUB -A <project_name>           # Shared across project
#CSUB -J <project>_<sample>       # Unique per job
#CSUB -q c01                      # Queue name
#CSUB -n 16                       # CPU cores (see Step 2)
#CSUB -R rusage[mem=176G]         # Memory (c01: 11GB/core)
#CSUB -R span[hosts=1]            # Single-node constraint
#CSUB -o %J.out                   # Stdout (%J = job ID)
#CSUB -e %J.err                   # Stderr
#CSUB -cwd /share/org/BGI/<user>/projects/<project>/

source /opt/skyformai/etc/aip.sh          # AIP env (mandatory)
module load <software/version>            # CPU jobs
# OR for GPU/AI:
# source /share/apps/anaconda3/bin/activate
# conda activate <env_name>

./your_script.sh                          # Your command
```

### Special Cases

| Scenario | Rule |
|----------|------|
| GPU/AI jobs | Use conda (not module) — they conflict |
| MPI jobs | Use `ompi-mpirun` (not native `mpirun`), cores as multiples of 48 |
| Interactive debug | Add `#CSUB -Is` for interactive output |

---

## Step 4: Submit Jobs

```bash
csub < job.aip          # Submit via stdin redirect
cjobs                   # Verify — csub may produce no output on success
```

### Batch Submission

Use templates in `templates/`:
- **batch_from_list.sh** — from tab-separated sample list: `bash batch_from_list.sh samples.txt`
- **batch_from_array.sh** — from ID array: edit array, then run

Batch rules:
- `sleep 1` between `csub` calls to avoid scheduler overload
- Create `.aip` files and submit in a **single SSH call** (sessions don't share context)
- Use consistent `-A` across all jobs in the same pipeline

---

## Common Pitfalls

1. **Authentication failed**: Must `source /opt/skyformai/etc/aip.sh` in every SSH session
2. **aip command not found**: AIP binaries in `/opt/skyformai/bin/`, only added by `aip.sh`
3. **c01 memory limit**: 11GB/core fixed — jobs exceeding `cores x 11GB` are killed
4. **GPU module/conda conflict**: Use conda exclusively for AI frameworks
5. **Batch overload**: Add `sleep 1` between `csub` calls
6. **Heredoc variables**: Use `<< 'EOF'` to prevent expansion; use `<<EOF` (unquoted) for template variables like `${sn}`
7. **csub silent success**: Always verify with `cjobs`
8. **Two SSH calls don't share files**: Create + submit in a single `ssh` command

## Next Steps

- After submitting: check job status with `HNAICC_job_monitor`
- When jobs complete: view output with `HNAICC_job_logs`
