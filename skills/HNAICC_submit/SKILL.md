---
name: HNAICC_submit
description: Use when submitting, managing, or troubleshooting jobs on the HNAICC cluster via SSH + csub/AIP scheduler -- covers SSH setup, AIP environment loading, job script creation, single and batch submission, queue management, and common failure modes.
version: 2.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [hnaicc, hpc, cluster, lsf, job-scheduling, aip, csub, batch-submission, bioinformatics]
    related_skills: [hpc-job-submission, bioinformatics-agent, single-cell-analysis]
---

# HNAICC Submit -- SSH + csub/AIP Job Submission

## Overview

Complete workflow for connecting to and submitting jobs on the HNAICC (华大国家基因库) cluster. The cluster uses SkyForm AIP (an LSF-based scheduler) accessible via `csub` commands over SSH. This skill covers the end-to-end process: SSH connection, AIP environment setup, writing `.aip` job scripts, submitting single or batch jobs, monitoring, and troubleshooting.

## When to Use

- Connecting to the HNAICC cluster and verifying SSH setup
- Submitting computational jobs via `csub` to the HNAICC cluster
- Writing `.aip` job submission scripts with correct `#CSUB` parameters
- Batch-submitting multiple jobs from sample lists or ID arrays
- Checking cluster status, queue utilization, and job progress
- Debugging job failures, authentication errors, or scheduling issues

**Don't use for:** Slurm clusters (`sbatch`/`srun`), PBS/Torque (`qsub`), or local machine execution. For generic LSF/AIP clusters (not HNAICC), use the `hpc-job-submission` skill instead.

## Cluster Architecture

- **AIP Version**: 10.25.0
- **Master Node**: s01n003 (cadmin)
- **Total Nodes**: 1,076
- **Login Node**: ln01n001 (SSH entry point: `phssh.hnaicc.cn:13310`)
- **Default Work Dir**: `/share/org/BGI/<username>/`
- **Node tiers**:
  - s01 series: 48 cores, 512GB RAM (few nodes)
  - c01 series: 88 cores, 1TB RAM, 2x Intel 8458P, NDR 200G (1000+ nodes, primary compute)

---

## Step 1: SSH Connection

### Configuration

Each user needs their own SSH credentials. Add to `~/.ssh/config`:

```
Host login_www
    HostName phssh.hnaicc.cn
    User <your_username>
    ForwardAgent yes
    Port <your_port>
    IdentityFile ~/.ssh/<your_key>
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

### Key Permissions

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/<your_key>
```

### Test Connection

```bash
ssh login_www "hostname && whoami"
# Expected: ln01n001, your_username
```

---

## Step 2: Load AIP Environment

**CRITICAL** -- Every SSH session must load the AIP environment before using cluster commands:

```bash
source /opt/skyformai/etc/aip.sh
```

This sets `CB_ENVDIR`, `LSF_ENVDIR`, `PATH` (adds `/opt/skyformai/bin`), and other required variables.

**Without this, `csub` fails silently with `Authentication failed`** -- the exit code may still be 0, making it easy to miss. `aip_user` throws `KeyError: 'CB_ENVDIR'`.

**Add to `~/.bashrc` for auto-loading:**
```bash
source /opt/skyformai/etc/aip.sh
```

---

## Step 3: Check Cluster Status

```bash
aip cluster info        # All nodes overview
aip queue info          # Queue status (capacity, running jobs)
aip host info           # Host load summary
aip host info <host>    # Specific host
aip host res            # Resource details
aip host res <host>     # Specific host resources
aip j i -p <jobid>      # Job resource utilization (CPU/GPU/memory)
```

---

## Step 4: Write AIP Job Script

### Standard Structure

```bash
#!/bin/bash
# ========== Resource Parameters (#CSUB) ==========
#CSUB -J <jobname>                      # Job name (visible in cjobs)
#CSUB -q <queue>                        # Queue name
#CSUB -n <cores>                        # CPU cores
#CSUB -o %J.out                         # Stdout (%J = job ID)
#CSUB -e %J.err                         # Stderr
#CSUB -R rusage[mem=<size>]             # Memory request
#CSUB -R span[hosts=1]                  # Single-node constraint
#CSUB -cwd <directory>                  # Working directory
#CSUB -A <account>                      # Billing account/project
#CSUB -Is                               # Interactive output (debug only)

# ========== Environment ==========
source /opt/skyformai/etc/aip.sh        # AIP env (if not in .bashrc)
module load <software/version>          # Software modules (CPU jobs)
export PATH=/opt/skyformai/bin:$PATH

# For GPU/AI jobs: use conda (not module)
# source /share/apps/anaconda3/bin/activate
# conda activate <env_name>

# ========== Execute ==========
./your_script.sh                        # Your actual computation
```

### #CSUB Parameter Reference

| Parameter | Description | Example |
|-----------|-------------|---------|
| `-J <name>` | Job name | `#CSUB -J rna_analysis` |
| `-q <queue>` | Queue name | `#CSUB -q c01` |
| `-n <num>` | CPU cores | `#CSUB -n 16` |
| `-o <file>` | Stdout file | `#CSUB -o %J.out` |
| `-e <file>` | Stderr file | `#CSUB -e %J.err` |
| `-cwd <dir>` | Working directory | `#CSUB -cwd /share/home/xxx/test` |
| `-Is` | Interactive output | `#CSUB -Is` |
| `-A <account>` | Billing account | `#CSUB -A project_name` |
| `-R rusage[mem=X]` | Memory request | `#CSUB -R rusage[mem=160G]` |
| `-R span[hosts=N]` | Node count | `#CSUB -R span[hosts=1]` |

### Queue & Core Limits

| Queue | Purpose | Core Limit | Memory | Notes |
|-------|---------|------------|--------|-------|
| c01 | Dedicated (BGI) | 1/2/4/8/16/32/44/64/88 | 11GB/core | **Primary queue** |
| cpu | General CPU | -n < 48 | Standard | Default queue |
| fat4 | Large memory (4-socket) | -n < 96 | High | Memory-intensive |
| fat8 | Very large memory (8-socket) | -n < 192 | Very high | Very large datasets |
| gpu | General GPU | -n < 4 | Standard | GPU computing |
| gpu_100 | A100 GPUs | 6 cores = 1 GPU | Standard | AI/Deep Learning |
| test | Testing | Small | Short | Debugging |

**c01 queue details (most commonly used):**
- Hardware: 2x Intel 8458P | 1TB RAM | NDR 200G
- **Memory: 11GB per core fixed** (16 cores = 176GB, 32 cores = 352GB)
- Jobs exceeding `cores x 11GB` are killed by the system
- Allowed core counts: 1,2,4,8,16,32,44,64,88,176,264,352...
- Scheduling: FAIRSHARE + EXCLUSIVE

### GPU-Specific Rules

1. PATH must include `/opt/skyformai/bin`
2. Use conda (not module) for AI frameworks -- module + conda conflict
3. Verify GPU allocation: `env | grep CUDA`
4. Activation pattern:
   ```bash
   source /share/apps/anaconda3/bin/activate
   conda activate <env_name>
   ```

### MPI Multi-Node

1. Use `ompi-mpirun` (cluster wrapper), NOT native `mpirun`
2. Core count should be multiples of 48
3. PATH must include `/opt/skyformai/bin`

---

## Step 5: Submit & Monitor

### Submit

```bash
csub < job.aip          # Via stdin redirect (most common)
```

### Monitor

```bash
cjobs                   # All your jobs
cjobs -w <jobid>        # Specific job (any status, including DONE)
ckill <jobid>           # Kill job
cstop <jobid>           # Pause job
cresume <jobid>         # Resume paused job
ctop <jobid>            # Highest priority
cbot <jobid>            # Lowest priority
cswitch                 # Switch queue
man csub                # Full manual
```

### View Output

```bash
cat <jobid>.out         # Standard output
cat <jobid>.err         # Error output
aip j i -p <jobid>      # Resource utilization
```

---

## Step 6: Batch Submission

### Pattern A: From Sample List File

```bash
#!/bin/bash
# Usage: bash batch_from_list.sh samples.txt
LIST_FILE="${1:-samples.txt}"
[ ! -f "$LIST_FILE" ] && { echo "Missing: $LIST_FILE"; exit 1; }

mkdir -p aip_scripts logs

while read -r sn fq olg; do
    [ -z "$sn" ] && continue
    AIP_FILE="aip_scripts/job_${sn}.aip"
    cat <<EOF > "$AIP_FILE"
#!/bin/bash
#CSUB -J job_${sn}
#CSUB -n 16
#CSUB -q c01
#CSUB -R rusage[mem=176G]
#CSUB -R span[hosts=1]
#CSUB -o logs/${sn}.out
#CSUB -e logs/${sn}.err
source /opt/skyformai/etc/aip.sh
./run_analysis.sh ${sn} ${fq} ${olg}
EOF
    csub < "$AIP_FILE"
    sleep 1
done < "$LIST_FILE"
```

### Pattern B: From ID Array

```bash
#!/bin/bash
id_list=("ID001" "ID002" "ID003")
mkdir -p aip_scripts logs

for id in "${id_list[@]}"; do
    AIP_FILE="aip_scripts/job_${id}.aip"
    cat <<EOF > "$AIP_FILE"
#!/bin/bash
#CSUB -J job_${id}
#CSUB -n 32
#CSUB -q c01
#CSUB -R rusage[mem=352G]
#CSUB -R span[hosts=1]
#CSUB -o logs/${id}.out
#CSUB -e logs/${id}.err
source /opt/skyformai/etc/aip.sh
python3 process.py ${id}
EOF
    chmod +x "$AIP_FILE"
    csub < "$AIP_FILE"
    sleep 1
done
```

---

## Quick Start (5-Minute Guide)

For the most common workflow -- submit a single job and check results:

```bash
# 1. Connect
ssh login_www

# 2. Load AIP environment (or add to ~/.bashrc)
source /opt/skyformai/etc/aip.sh

# 3. Create job script
cat > myjob.aip << 'EOF'
#!/bin/bash
#CSUB -J my_job
#CSUB -q c01
#CSUB -n 16
#CSUB -R rusage[mem=176G]
#CSUB -R span[hosts=1]
#CSUB -o %J.out
#CSUB -e %J.err
echo "Hello from HNAICC cluster"
date
python3 --version
EOF

# 4. Submit
csub < myjob.aip

# 5. Check
cjobs          # see status
cat *.out      # see output
cat *.err      # see errors
```

---

## Common Pitfalls

1. **Authentication failed**: Must `source /opt/skyformai/etc/aip.sh` in every SSH session. Without it, csub prints `Failed in an AIP library call: Authentication failed. Job not submitted.` -- the exit code may still be 0, making it easy to miss. Add to `~/.bashrc`.

2. **aip command not found**: AIP binaries are in `/opt/skyformai/bin/`, only added to PATH by `aip.sh`. The default PATH is `/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin`.

3. **SSH key permissions**: Must be 600. Error: `Permissions 0644 for '~/.ssh/xxx' are too open.` Fix: `chmod 600 ~/.ssh/<key>`.

4. **Two SSH sessions don't share shell context**: When scripting via SSH from external machines, files created in one `ssh` call may not be visible to the next call. Always create + submit in a single `ssh` command.

5. **c01 memory limit**: 11GB per core fixed. If you request `-n 16`, you get exactly 176GB. If your process needs more, request more cores (e.g., `-n 32` for 352GB).

6. **GPU module/conda conflict**: On GPU nodes, `module load` alongside conda causes library conflicts. Use conda exclusively for AI frameworks.

7. **Batch submission overload**: Scheduler stressed by rapid submissions. Add `sleep 1` between `csub` calls.

8. **Variable expansion in heredoc**: Use `<< 'EOF'` (single-quoted) to prevent premature expansion. Variables like `$JOB_ID` inside the generated script will expand correctly on the compute node.

9. **csub returns empty on success**: `csub < job.aip` may produce no visible output even on success. Check with `cjobs` or `cjobs -w <jobid>` after submission.

10. **DONE jobs disappear from cjobs**: Completed jobs may not show in plain `cjobs`. Use `cjobs -w <jobid>` to query a specific job regardless of status.

## Verification Checklist

- [ ] SSH config has correct User, Port, IdentityFile for your account
- [ ] SSH key permissions are 600
- [ ] `source /opt/skyformai/etc/aip.sh` runs without error
- [ ] `csub < test.aip` submits successfully (check with `cjobs`)
- [ ] Core count (-n) is valid for the target queue
- [ ] Memory (rusage) does not exceed queue limits (c01: 11GB/core)
- [ ] Output/error files use %J to avoid overwrites
- [ ] Batch submissions include sleep 1 between jobs
- [ ] GPU jobs use conda, not module, for AI frameworks
- [ ] MPI jobs use ompi-mpirun, not mpirun

## Linked Files

### Templates

| File | Purpose | Usage |
|------|---------|-------|
| `templates/basic_job.aip` | Single job submission template | Copy, modify parameters, `csub < basic_job.aip` |
| `templates/batch_from_list.sh` | Batch from tab-separated sample list | `bash batch_from_list.sh samples.txt` |
| `templates/batch_from_array.sh` | Batch from hardcoded ID array | Edit array, then `bash batch_from_array.sh` |

### References

| File | Purpose |
|------|---------|
| `references/queue_reference.md` | Queue specs, node architecture, memory calculations |
