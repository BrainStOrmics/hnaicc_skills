---
name: HNAICC_job_monitor
description: Use when the user mentions checking job status, queue utilization, or cluster info on the HNAICC cluster - covers cjobs, queue management, and job control commands. Do NOT use for viewing job output or diagnosing errors (use HNAICC_job_logs).
version: 2.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [hnaicc, hpc, cluster, lsf, job-monitoring, queue-management, cjobs]
    related_skills: [HNAICC_ssh, HNAICC_project_setup, HNAICC_env_setup, HNAICC_aip_submit, HNAICC_job_logs]
---

# HNAICC Job Monitor — Task Status & Queue Management

## Checklist

1. **SSH credentials configured** — verify `login_www` works (see HNAICC_ssh skill)
2. **Load AIP environment** — `source /opt/skyformai/etc/aip.sh`
3. **Check job status** — `cjobs` for active, `cjobs -w <jobid>` for specific
4. **Check queue/cluster** — `aip queue info`, `aip cluster info`

**Don't use for:** SSH setup (use `HNAICC_ssh`), job submission (use `HNAICC_aip_submit`), or analyzing job logs (use `HNAICC_job_logs`).

## Job Status

```bash
cjobs                   # All active jobs (PEND, RUN, PSUSP)
cjobs -w <jobid>        # Specific job, any status (including DONE, EXIT)
```

**Note:** DONE/EXIT jobs don't appear in plain `cjobs`. Always use `cjobs -w <jobid>` for completed jobs.

### Status Codes

| Status | Meaning | Action |
|--------|---------|--------|
| PEND | Waiting for resources | Check queue capacity |
| RUN | Executing | Monitor with `aip j i -p <jobid>` |
| DONE | Completed | View logs via `HNAICC_job_logs` |
| EXIT | Failed | Diagnose errors via `HNAICC_job_logs` |
| PSUSP | Paused by user | Resume with `cresume` |
| SSUSP | Suspended by system | Wait or contact admin |

## Job Management

| Command | Description |
|---------|-------------|
| `ckill <jobid>` | Terminate |
| `cstop <jobid>` | Pause |
| `cresume <jobid>` | Resume |
| `ctop <jobid>` | Highest priority |
| `cbot <jobid>` | Lowest priority |

```bash
# Kill all pending jobs
cjobs | grep PEND | awk '{print $1}' | xargs -I{} ckill {}
```

## Cluster & Queue Info

```bash
aip cluster info        # All nodes overview
aip queue info          # Queue status (capacity, running jobs)
aip host info           # Host load summary
aip host res <host>     # Specific host resources
aip j i -p <jobid>      # Job CPU/GPU/memory utilization
aip_user                # Account info, queue permissions
```

### Queue Reference

| Queue | Cores | Memory | Notes |
|-------|-------|--------|-------|
| c01 | 1/2/4/8/16/32/44/64/88 | 11GB/core | **Primary (BGI)** |
| cpu | < 48 | Standard | General purpose |
| fat4 | < 96 | High | Memory-intensive |
| fat8 | < 192 | Very high | Very large datasets |
| gpu_100 | 6 cores = 1 GPU | Standard | A100, AI/DL |
| test | Small | Short | Debugging |

## Common Pitfalls

- **DONE jobs disappear from `cjobs`**: Use `cjobs -w <jobid>` for completed jobs
- **Job stuck in PEND**: Queue full or FAIRSHARE priority low — check `aip queue info`
- **aip command not found**: Load AIP environment first
- **Resource utilization shows zero**: Job may still be PEND or monitoring interval hasn't captured data

## Next Steps

- Job DONE: use `HNAICC_job_logs` to view output
- Job EXIT: use `HNAICC_job_logs` to diagnose errors
- Submit more jobs: use `HNAICC_aip_submit`
