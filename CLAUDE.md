# HNAICC Submit — Agent Instructions

You are working with the HNAICC (华大国家基因库) HPC cluster. This repo contains the complete skill for connecting to and submitting jobs on the cluster.

## When This Applies

Activate when the user mentions: HNAICC, cluster, csub, aip, job submission, batch submit, queue, compute node, login node, or any task involving running computational jobs on a remote HPC cluster.

## First Steps

1. **Read the skill completely** before attempting any cluster operation:
   - Primary: `skills/HNAICC_submit/SKILL.md`
   - Templates: `skills/HNAICC_submit/templates/`
   - Reference: `skills/HNAICC_submit/references/queue_reference.md`

2. **Never skip the AIP environment loading step.** This is the #1 cause of failure.

## Critical Rules

These rules are absolute. Never violate them:

1. **MUST load AIP environment**: `source /opt/skyformai/etc/aip.sh` in every SSH session. Without this, `csub` fails with `Authentication failed` (exit code may still be 0).

2. **SSH key permissions**: Must be 600. `chmod 600 ~/.ssh/<key>`.

3. **c01 memory limit**: 11GB per core is fixed. Jobs exceeding `cores x 11GB` are killed by the system.

4. **Use `ompi-mpirun`**, not native `mpirun`, for MPI jobs.

5. **GPU jobs use conda**, not module, for AI frameworks.

6. **Batch submissions need `sleep 1`** between `csub` calls to avoid scheduler overload.

## Quick Workflow

```bash
ssh login_www                               # Connect
source /opt/skyformai/etc/aip.sh            # CRITICAL: Load AIP env
aip queue info                              # Check resources
csub < myjob.aip                            # Submit
cjobs                                       # Monitor
cat <jobid>.out                             # View output
```

## File Structure

```
skills/HNAICC_submit/
├── SKILL.md                    # Main skill document (read first)
├── templates/
│   ├── basic_job.aip           # Single job template
│   ├── batch_from_list.sh      # Batch from sample list
│   └── batch_from_array.sh     # Batch from ID array
└── references/
    └── queue_reference.md      # Queue specs and cluster details
```

## Common Pitfalls (Check These First)

- Job submission returns no output? Check with `cjobs` -- csub may succeed silently.
- `aip` command not found? Load AIP environment first.
- Completed jobs missing from `cjobs`? Use `cjobs -w <jobid>`.
- Two SSH calls don't share files? Create + submit in single SSH call.

Always verify job submission succeeded by checking `cjobs` immediately after `csub`.
