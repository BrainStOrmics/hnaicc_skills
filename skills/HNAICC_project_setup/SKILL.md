---
name: HNAICC_project_setup
description: Use when the user mentions setting up a project directory or organizing sample data on the HNAICC cluster - creates directory structures and prepares work environments. Do NOT use for file transfers (use HNAICC_sftp).
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [hnaicc, hpc, cluster, project-management, directory-setup, data-organization]
    related_skills: [HNAICC_ssh, HNAICC_sftp, HNAICC_aip_submit]
---

# HNAICC Project Setup — Project Directory & Data Management

## Checklist

1. **SSH credentials configured** — verify `login_www` works (see HNAICC_ssh skill)
2. **Create project directory structure** — standard layout under `/share/org/BGI/<username>/projects/`
3. **Verify directory structure** — confirm all subdirectories exist
4. **Create sample list file** — for batch processing workflows
5. **Set working directory context** — ensure paths resolve correctly for job scripts

**Don't use for:** SSH setup (use `HNAICC_ssh`), file transfer (use `HNAICC_sftp`), or job submission (use `HNAICC_aip_submit`).

## Standard Project Layout

```bash
ssh login_www "cd /share/org/BGI/<username> && mkdir -p projects/<project_name>/{raw_data,scripts,aip_scripts,logs,results,tmp}"
```

| Directory | Purpose |
|-----------|---------|
| `raw_data/` | Input files (FASTQ, BAM, CSV, etc.) |
| `scripts/` | Analysis scripts and pipeline code |
| `aip_scripts/` | Generated `.aip` job scripts |
| `logs/` | Job output (`.out`) and error (`.err`) files |
| `results/` | Analysis output and processed data |
| `tmp/` | Temporary/intermediate files |

## Step 1: Create Project

```bash
ssh login_www "mkdir -p /share/org/BGI/<username>/projects/<project_name>/{raw_data,scripts,aip_scripts,logs,results,tmp}"
```

## Step 2: Verify Structure

```bash
ssh login_www "
cd /share/org/BGI/<username>/projects/<project_name>
echo '=== Directory structure ==='
find . -maxdepth 2
echo ''
echo '=== Disk usage ==='
du -sh .
"
```

## Step 3: Generate Sample List (Optional)

For batch processing, create a sample list:

```bash
ssh login_www "
cd /share/org/BGI/<username>/projects/<project_name>/raw_data
# Adjust pattern based on file naming convention
ls *.fastq.gz | sed 's/_R1.fastq.gz//' | sort -u > ../scripts/samples.txt
echo 'Samples found:'
cat ../scripts/samples.txt | wc -l
"
```

Sample list formats:
- **Simple**: one sample name per line
- **Tab-separated**: `sample_name\tfastq_path\tmetadata`
- **CSV**: `sample_id,fastq1,fastq2,condition`

## Step 4: Set Working Directory for Jobs

All `.aip` scripts should set `-cwd` to the project root:

```bash
#CSUB -cwd /share/org/BGI/<username>/projects/<project_name>
#CSUB -o logs/%J.out
#CSUB -e logs/%J.err
```

## Common Pitfalls

- **Path mismatch**: Ensure `-cwd` in `.aip` scripts matches the actual project directory.
- **Large uploads fail silently**: Use `rsync --partial` for large files.
- **Sample list format wrong**: Verify format matches what the batch script expects.
- **Disk quota exceeded**: Check with `df -h /share/` before uploading large datasets.

## Next Steps

- Upload data: use `HNAICC_sftp` skill
- Set up environments: use `HNAICC_env_setup` skill
- Submit jobs: use `HNAICC_aip_submit` skill
