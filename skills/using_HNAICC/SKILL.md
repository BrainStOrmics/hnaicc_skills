---
name: using_HNAICC
description: Use ONLY when the user explicitly mentions HNAICC (华大国家基因库/海南人工智能中心) cluster. Entry point and index for all HNAICC skills. Do NOT use for general SSH, file transfer, or job scheduling — defer to specialized skills when a specific task is requested.
version: 4.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [hnaicc, hpc, cluster, index, skill-registry]
    related_skills: [HNAICC_ssh, HNAICC_sftp, HNAICC_project_setup, HNAICC_env_setup, HNAICC_aip_submit, HNAICC_job_monitor, HNAICC_job_logs]
---

# using_HNAICC — HNAICC Cluster Skills Index

This skill is an entry point to the HNAICC (华大国家基因库/海南人工智能中心) cluster skill set. **Only activate when the user explicitly mentions HNAICC cluster.** Use the specialized skills below based on what you need to do.

## Cluster Overview

- **AIP Version**: 10.25.0 (SkyForm, LSF-based)
- **Master Node**: s01n003
- **Login Node**: ln01n001 (SSH: `phssh.hnaicc.cn`)
- **Total Nodes**: 1,076
- **Default Work Dir**: `/share/org/BGI/<username>/`
- **Primary Queue**: c01 (88 cores, 1TB RAM per node, 11GB/core memory)

## Skill Registry

| # | Skill | When to Use |
|---|-------|-------------|
| 1 | [`HNAICC_ssh`](../HNAICC_ssh/SKILL.md) | **First step** — SSH config, key setup, connection testing. All other skills depend on this. |
| 2 | [`HNAICC_project_setup`](../HNAICC_project_setup/SKILL.md) | Create project directory structure, organize samples, set up working directories |
| 3 | [`HNAICC_sftp`](../HNAICC_sftp/SKILL.md) | Upload/download files to/from the cluster (uses SSH credentials from step 1) |
| 4 | [`HNAICC_env_setup`](../HNAICC_env_setup/SKILL.md) | Set up conda environments, load software modules, verify GPU/software availability |
| 5 | [`HNAICC_aip_submit`](../HNAICC_aip_submit/SKILL.md) | Write `.aip` scripts, submit jobs via `csub`, batch submission |
| 6 | [`HNAICC_job_monitor`](../HNAICC_job_monitor/SKILL.md) | Check job status, queue info, cluster resources, manage jobs |
| 7 | [`HNAICC_job_logs`](../HNAICC_job_logs/SKILL.md) | View output/error logs, diagnose job failures, download logs |

## Workflow

```
1. HNAICC_ssh          → Configure SSH credentials, test connection
2. HNAICC_project_setup → Create project directory, organize samples
3. HNAICC_sftp         → Upload input data and scripts
4. HNAICC_env_setup    → Set up conda/module environments
5. HNAICC_aip_submit   → Write and submit .aip job scripts
6. HNAICC_job_monitor  → Check job status and queue utilization
7. HNAICC_job_logs     → View output/error logs after job completes
```

Steps 2-7 all depend on the SSH credentials configured in step 1.

## Golden Rules

1. **MUST load AIP environment**: `source /opt/skyformai/etc/aip.sh` in every SSH session
2. **SSH key permissions**: Must be 600
3. **c01 memory limit**: 11GB per core is fixed
4. **Use `ompi-mpirun`**, not native `mpirun`, for MPI jobs
5. **GPU jobs use conda**, not module, for AI frameworks
6. **Batch submissions need `sleep 1`** between `csub` calls
7. **Job naming**: `-A` (project-level, shared) vs `-J` (job-level, unique)
8. **Single SSH command**: Always combine file creation + submission in one `ssh` call
