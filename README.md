# HNAICC Submit

HNAICC cluster job submission skills for coding agents -- SSH connection, AIP/csub job scheduling, single and batch submission, queue management, and troubleshooting. Built for the HNAICC (华大国家基因库) HPC cluster using SkyForm AIP (LSF-based scheduler).

## Quickstart

Install for your agent: [Claude Code](#claude-code), [Codex](#codex), [OpenCode](#opencode), [Hermes Agent](#hermes-agent).

## How It Works

When you ask your agent to run something on the HNAICC cluster, it loads this skill and follows the documented workflow:

1. **SSH Connection** -- Verifies SSH config, key permissions, and connects to the login node.
2. **AIP Environment** -- Loads `/opt/skyformai/etc/aip.sh` (mandatory, otherwise authentication fails).
3. **Cluster Inspection** -- Checks queue status, node availability, and resource utilization.
4. **Job Script Creation** -- Writes `.aip` submission scripts with correct `#CSUB` parameters.
5. **Submission** -- Submits via `csub < job.aip`, monitors with `cjobs`.
6. **Batch Processing** -- For multiple samples/IDs, generates and submits one job per item with rate limiting.

The skill includes templates for common patterns: single jobs, sample-list batch submission, and ID-array batch submission. It also documents all queue specifications, core limits, memory constraints, and common failure modes.

## Installation

Installation differs by agent harness. Install separately for each one you use.

### Claude Code

**Option A: Clone as skills directory**

```bash
# Clone this repo
git clone https://github.com/BrainStOrmics/hnaicc_skills.git

# Symlink the skill into Claude's skills directory
ln -s $(pwd)/HNAICC-skill/skills/HNAICC_submit ~/.claude/skills/HNAICC_submit

# Or copy it
cp -r HNAICC-skill/skills/HNAICC_submit ~/.claude/skills/
```

**Option B: Project-level skills**

```bash
# In your project directory
mkdir -p .claude/skills
cp -r /path/to/HNAICC-skill/skills/HNAICC_submit .claude/skills/
```

Claude Code auto-loads skills from `~/.claude/skills/` (global) and `.claude/skills/` (project). When your task mentions HNAICC, cluster, csub, or job submission, Claude will automatically reference the skill.

### Codex

Codex does not have a standardized skills directory convention. Instead, reference the skill documentation directly in your project instructions.

**Option A: Project-level AGENTS.md reference**

Add to your project's `AGENTS.md` or `CLAUDE.md`:

```markdown
## HNAICC Cluster

For HNAICC cluster job submission, follow the skill at:
`skills/HNAICC_submit/SKILL.md`
```

**Option B: Clone and reference**

```bash
git clone https://github.com/BrainStOrmics/hnaicc_skills.git
```

Then tell Codex: "The HNAICC cluster job submission skill is at HNAICC-skill/skills/HNAICC_submit/SKILL.md"

### OpenCode

**Option A: Config reference**

Add to your `.opencode.json` or `.opencode/config.json`:

```json
{
  "skills": [
    {
      "name": "HNAICC_submit",
      "path": "skills/HNAICC_submit/SKILL.md"
    }
  ]
}
```

**Option B: Clone and reference**

```bash
git clone https://github.com/BrainStOrmics/hnaicc_skills.git
```

Then tell OpenCode: "Load the skill from HNAICC-skill/skills/HNAICC_submit/SKILL.md"

### Hermes Agent

```bash
# Install from local path
hermes skills install /path/to/HNAICC-skill/skills/HNAICC_submit/SKILL.md

# Or install from URL (after pushing to GitHub)
hermes skills install https://raw.githubusercontent.com/BrainStOrmics/hnaicc_skills.git

# Or tap the repo for auto-updates
hermes skills tap add https://github.com/BrainStOrmics/hnaicc_skills.git
hermes skills install HNAICC_submit
```

Verify installation:

```bash
hermes skills list | grep HNAICC
```

## The Workflow

### Single Job

```bash
# 1. Connect to cluster
ssh login_www

# 2. Load AIP environment (or add to ~/.bashrc)
source /opt/skyformai/etc/aip.sh

# 3. Check resources
aip queue info

# 4. Submit job
csub < myjob.aip

# 5. Monitor
cjobs
cat <jobid>.out
```

### Batch Jobs

Use the templates in `skills/HNAICC_submit/templates/`:

- **`basic_job.aip`** -- Single job submission template
- **`batch_from_list.sh`** -- Submit from tab-separated sample list
- **`batch_from_array.sh`** -- Submit from hardcoded ID array

## What's Inside

### Skills

- **HNAICC_submit** -- Complete workflow for SSH connection, AIP environment loading, job script writing, submission, monitoring, batch processing, and troubleshooting on the HNAICC cluster.

### Templates

- **basic_job.aip** -- Standard single job submission with all `#CSUB` parameters documented
- **batch_from_list.sh** -- Batch submit from sample list file (sample_name, fastq_prefix, oligo_prefix)
- **batch_from_array.sh** -- Batch submit from ID array with status tracking and logging

### References

- **queue_reference.md** -- Detailed queue specifications, node architecture, memory calculations, command reference

## Key Constraints

| Queue | Cores | Memory | Notes |
|-------|-------|--------|-------|
| c01 | 1/2/4/8/16/32/44/64/88 | 11GB/core | Primary queue |
| cpu | < 48 | Standard | General purpose |
| fat4 | < 96 | High | 4-socket nodes |
| fat8 | < 192 | Very high | 8-socket nodes |
| gpu_100 | 6 cores = 1 GPU | Standard | A100 GPUs |

**Critical rules:**
- Must `source /opt/skyformai/etc/aip.sh` before any cluster command
- c01 queue: 11GB per core fixed (exceeding kills the job)
- GPU jobs: use conda, not module, for AI frameworks
- MPI jobs: use `ompi-mpirun`, not native `mpirun`
- Batch submissions: add `sleep 1` between `csub` calls

## Philosophy

- **Environment first** -- Always verify AIP environment before submitting
- **Start small** -- Test with `-Is` on a small sample before full batch
- **Monitor utilization** -- Use `aip j i -p <jobid>` to verify resource usage
- **Separate concerns** -- Business logic in `.sh`, submission params in `.aip`
- **Fail fast** -- Check `.err` files immediately, don't wait for all jobs to finish


## Syncing After Updates

After making changes, push to GitHub and sync to local agents:

```bash
# 1. Push to GitHub
cd HNAICC-skill
git add .
git commit -m "update: HNAICC_submit skill"
git push

# 2. Sync to local agents (Claude Code + Hermes)
bash sync-hnaicc-skill.sh

# 3. For Hermes remote update (if tapped the repo)
hermes skills update
```

The sync script (`sync-hnaicc-skill.sh`) automatically:
- Strips YAML frontmatter for Claude Code
- Copies the full SKILL.md (with frontmatter) for Hermes
- Copies templates and references to both locations

## License

MIT License
