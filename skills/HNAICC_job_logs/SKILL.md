---
name: HNAICC_job_logs
description: Use when the user mentions viewing or analyzing job logs, output files, or error diagnostics on the HNAICC cluster - covers log retrieval, error pattern recognition, and resource utilization analysis. Do NOT use for checking job status (use HNAICC_job_monitor).
version: 2.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [hnaicc, hpc, cluster, job-logs, debugging, output-analysis, error-diagnosis]
    related_skills: [HNAICC_ssh, HNAICC_project_setup, HNAICC_env_setup, HNAICC_aip_submit, HNAICC_job_monitor]
---

# HNAICC Job Logs — Output & Error Analysis

## Checklist

1. **SSH credentials configured** — verify `login_www` works (see HNAICC_ssh skill)
2. **Locate log files** — check `-o`/`-e` paths in the `.aip` script (default: `%J.out`/`%J.err`)
3. **Read logs** — `.out` for output, `.err` for errors
4. **Diagnose failures** — match error patterns below
5. **Check resource utilization** — `aip j i -p <jobid>` for CPU/GPU/memory usage

**Don't use for:** SSH setup (use `HNAICC_ssh`), checking job status (use `HNAICC_job_monitor`), or job submission (use `HNAICC_aip_submit`).

## Log File Locations

Logs are set by `#CSUB -o` (stdout) and `#CSUB -e` (stderr) in the `.aip` script, relative to `-cwd`:

```
%J.out    # Standard output (%J = job ID)
%J.err    # Standard error
```

```bash
cat <jobid>.out              # Full output
tail -n 50 <jobid>.err       # Last 50 lines of error
grep -i "error\|fail\|killed\|exception" <jobid>.*  # Search for problems
```

## Resource Utilization

```bash
aip j i -p <jobid>      # CPU/GPU/memory utilization
```

Use to: verify core usage, check if memory neared the limit, diagnose GPU issues, right-size future jobs.

## Common Pitfalls

| Error | Cause | Fix |
|-------|-------|-----|
| `Authentication failed` | AIP env not loaded before `csub` | `source /opt/skyformai/etc/aip.sh` before submission |
| `Killed` | OOM — exceeded `cores x 11GB` on c01 | Request more cores (e.g., `-n 16` → `-n 32`) |
| `CUDA error` / `No CUDA device` | Used `module` for AI framework or GPU not allocated | Use conda for AI; verify `env \| grep CUDA` |
| `command not found` | Missing env setup in `.aip` script | Add `source /opt/skyformai/etc/aip.sh` and `module load` to `.aip` |
| `mpirun: command not found` | Used native `mpirun` | Use `ompi-mpirun` instead |
| `Job cannot be submitted to requested queue` | Invalid core count for queue | c01 accepts only: 1,2,4,8,16,32,44,64,88 |
| `ModuleNotFoundError` | Conda env not activated in `.aip` | Add `conda activate <env>` to `.aip` script |

## Quick Diagnostic Flow

1. Job EXIT → check `<jobid>.err` first
2. Job DONE but output incomplete → check `<jobid>.out`
3. Memory seems high → `aip j i -p <jobid>` for actual utilization
4. No log files → check if `-cwd` was set correctly
5. `Killed` → likely OOM, increase cores

## Download Logs Locally

```bash
scp login_www:/share/org/BGI/<username>/projects/<project>/logs/<jobid>.out ./
scp -r login_www:/share/org/BGI/<username>/projects/<project>/logs/ ./local_logs/
```

## Next Steps

- After diagnosing: fix `.aip` script and resubmit via `HNAICC_aip_submit`
- Check cluster status: use `HNAICC_job_monitor`
