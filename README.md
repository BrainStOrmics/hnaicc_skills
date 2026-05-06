# HNAICC Skills

Agent skills for connecting to and running workloads on the HNAICC (华大国家基因库 / 海南人工智能中心) HPC cluster. Covers SSH setup, file transfer, project layout, environment configuration, AIP/csub job submission, monitoring, and log analysis. Built for the SkyForm AIP (LSF-based v10.25.0) scheduler.

## Installation (Recommended): Auto Sync

The quickest way to install all skills locally:

```bash
git clone https://github.com/BrainStOrmics/hnaicc_skills.git
cd hnaicc_skills
bash sync-hnaicc-skill.sh
```

The sync script automatically installs all 8 skills to both **Claude Code** (`~/.claude/skills/`) and **Hermes Agent** (`~/.hermes/skills/`):
- Strips YAML frontmatter for Claude Code
- Keeps full frontmatter for Hermes (it parses it)
- Copies `templates/` and `references/` subdirectories where they exist

Dry-run (preview without copying):

```bash
bash sync-hnaicc-skill.sh --dry-run
```

For Hermes remote update (if you tapped the repo):

```bash
hermes skills update
```

## Per-Agent Installation (Manual)

If you don't want to use the sync script, install skills individually:

### Claude Code

```bash
git clone https://github.com/BrainStOrmics/hnaicc_skills.git

# Symlink all skills (global)
cd hnaicc_skills
for skill in skills/*/; do
    ln -s "$(pwd)/$skill" "$HOME/.claude/skills/$(basename $skill)"
done
```

Or copy for a specific project:

```bash
# In your project directory
mkdir -p .claude/skills
cp -r /path/to/hnaicc_skills/skills/* .claude/skills/
```

Claude Code auto-loads skills from `~/.claude/skills/` (global) and `.claude/skills/` (project).

### Codex

Codex doesn't have a standard skills directory. Reference the skill docs directly:

```bash
git clone https://github.com/BrainStOrmics/hnaicc_skills.git
```

Then tell Codex: "The HNAICC skills are in `skills/using_HNAICC/SKILL.md` (entry point)."

### OpenCode

Add to `.opencode.json`:

```json
{
  "skills": [
    { "name": "using_HNAICC", "path": "skills/using_HNAICC/SKILL.md" },
    { "name": "HNAICC_ssh", "path": "skills/HNAICC_ssh/SKILL.md" },
    { "name": "HNAICC_aip_submit", "path": "skills/HNAICC_aip_submit/SKILL.md" }
  ]
}
```

### Hermes Agent

```bash
# Install individual skills from local path
for skill in using_HNAICC HNAICC_ssh HNAICC_sftp HNAICC_project_setup HNAICC_env_setup HNAICC_aip_submit HNAICC_job_monitor HNAICC_job_logs; do
    hermes skills install skills/$skill/SKILL.md
done

# Or tap the repo for auto-updates
hermes skills tap add https://github.com/BrainStOrmics/hnaicc_skills.git
hermes skills install using_HNAICC
```

Verify: `hermes skills list | grep HNAICC`

## How It Works

When you ask your agent to work on the HNAICC cluster, it loads the relevant skill and follows this workflow:

```
SSH Setup → SFTP Transfer → Project Setup → Env Setup → AIP Submit → Monitor → Logs
```

1. **SSH Connection** (`HNAICC_ssh`) — Configures SSH credentials, verifies key permissions, connects to `phssh.hnaicc.cn`.
2. **File Transfer** (`HNAICC_sftp`) — Uploads input data, scripts; downloads results and logs.
3. **Project Layout** (`HNAICC_project_setup`) — Creates standard directory structure, generates sample lists.
4. **Environment** (`HNAICC_env_setup`) — Loads modules (CPU jobs) or creates conda environments (GPU/AI jobs).
5. **Job Submission** (`HNAICC_aip_submit`) — Writes `.aip` scripts with `#CSUB` parameters, submits via `csub`, handles batch submission.
6. **Monitoring** (`HNAICC_job_monitor`) — Checks job status with `cjobs`, manages queue, controls job priority.
7. **Log Analysis** (`HNAICC_job_logs`) — Reads `.out`/`.err` files, diagnoses failures, checks resource utilization.

## Skills

| Skill | When It Triggers |
|-------|-----------------|
| [`using_HNAICC`](skills/using_HNAICC/SKILL.md) | Entry point — user mentions HNAICC cluster generally |
| [`HNAICC_ssh`](skills/HNAICC_ssh/SKILL.md) | Connecting, logging in, SSH credentials |
| [`HNAICC_sftp`](skills/HNAICC_sftp/SKILL.md) | Uploading, downloading, transferring files |
| [`HNAICC_project_setup`](skills/HNAICC_project_setup/SKILL.md) | Setting up project directories, organizing samples |
| [`HNAICC_env_setup`](skills/HNAICC_env_setup/SKILL.md) | Conda environments, module loading, software setup |
| [`HNAICC_aip_submit`](skills/HNAICC_aip_submit/SKILL.md) | Creating/submitting `.aip` job scripts, batch submission |
| [`HNAICC_job_monitor`](skills/HNAICC_job_monitor/SKILL.md) | Checking job status, queue utilization, cluster info |
| [`HNAICC_job_logs`](skills/HNAICC_job_logs/SKILL.md) | Viewing logs, error diagnostics, resource analysis |

## Templates

Located in `skills/HNAICC_aip_submit/templates/`:

| Template | Usage |
|----------|-------|
| `basic_job.aip` | Single job submission — copy, edit params, `csub < job.aip` |
| `batch_from_list.sh` | Batch from tab-separated sample list: `bash batch_from_list.sh samples.txt` |
| `batch_from_array.sh` | Batch from hardcoded ID array: edit array, then `bash batch_from_array.sh` |

## Queue Reference

| Queue | Cores | Memory | Notes |
|-------|-------|--------|-------|
| c01 | 1/2/4/8/16/32/44/64/88 | 11GB/core | Primary queue (BGI) |
| cpu | < 48 | Standard | General purpose |
| fat4 | < 96 | High | 4-socket, memory-intensive |
| fat8 | < 192 | Very high | 8-socket, large datasets |
| gpu | < 4 | Standard | GPU computing |
| gpu_100 | 6 cores = 1 GPU | Standard | A100, AI/DL |
| test | Small | Short | Debugging |

## Key Constraints

- **AIP environment required**: `source /opt/skyformai/etc/aip.sh` before any cluster command
- **c01 memory**: 11GB per core is fixed — exceeding it kills the job
- **GPU jobs**: use conda exclusively for AI frameworks (module + conda conflict)
- **MPI jobs**: use `ompi-mpirun`, not native `mpirun`
- **Batch submissions**: add `sleep 1` between `csub` calls
- **SSH key permissions**: must be 600

## Testing

```bash
# Run all tests
bash tests/run-all.sh

# Individual suites
bash tests/structure/test-skill-structure.sh
bash tests/validation/test-skill-content.sh
bash tests/skill-triggering/test-skill-descriptions.sh
```

## License

MIT License
