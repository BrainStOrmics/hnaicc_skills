---
name: HNAICC_sftp
description: Use when the user mentions uploading, downloading, or transferring files to or from the HNAICC cluster - covers SFTP, SCP, and rsync operations. Do NOT use for SSH setup (use HNAICC_ssh) or job submission.
version: 2.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [hnaicc, hpc, cluster, sftp, scp, file-transfer, data-movement]
    related_skills: [HNAICC_ssh, HNAICC_project_setup, HNAICC_aip_submit]
---

# HNAICC SFTP — File Transfer

## Checklist

1. **SSH credentials configured** — verify `login_www` works (see HNAICC_ssh skill)
2. **Transfer files** — upload input data/scripts or download results/logs
3. **Verify transfer** — confirm file counts and sizes match expectations

**Don't use for:** SSH setup (use `HNAICC_ssh`), job submission (use `HNAICC_aip_submit`), or job monitoring (use `HNAICC_job_monitor`).

## Default Work Directory

```
/share/org/BGI/<username>/
```

For organized projects:
```
/share/org/BGI/<username>/projects/<project_name>/{raw_data,scripts,aip_scripts,logs,results,tmp}
```

## Upload Files

### Single File

```bash
scp local_file.txt login_www:/share/org/BGI/<username>/projects/<project>/raw_data/
```

### Directory

```bash
scp -r local_dir/ login_www:/share/org/BGI/<username>/projects/<project>/
```

### Large Files (Recommended)

```bash
rsync -avz --partial --progress local_dir/ login_www:/share/org/BGI/<username>/projects/<project>/target_dir/
```

Use `rsync` for:
- Files > 1GB (resume capability with `--partial`)
- Syncing only changed files (incremental)
- Preserving permissions and timestamps

## Download Files

### Single File

```bash
scp login_www:/share/org/BGI/<username>/projects/<project>/results/output.txt ./
```

### Directory

```bash
scp -r login_www:/share/org/BGI/<username>/projects/<project>/results/ ./local_results/
```

### With rsync

```bash
rsync -avz --progress login_www:/share/org/BGI/<username>/projects/<project>/results/ ./local_results/
```

## Interactive SFTP

```bash
sftp login_www
sftp> ls           # List remote files
sftp> lls          # List local files
sftp> cd <dir>     # Change remote directory
sftp> lcd <dir>    # Change local directory
sftp> put file     # Upload
sftp> get file     # Download
sftp> mkdir <dir>  # Create remote directory
sftp> exit
```

## Batch Mode

```bash
sftp -b - login_www <<EOF
cd /share/org/BGI/<username>/projects/<project>/
mkdir -p input_data
put ./data/*.fastq.gz input_data/
exit
EOF
```

## Verify Transfer

```bash
# Compare file counts
echo "Local: $(ls local_dir/ | wc -l) files"
echo "Remote: $(ssh login_www 'ls /share/org/BGI/<username>/projects/<project>/raw_data/ | wc -l') files"

# Check remote disk usage
ssh login_www "du -sh /share/org/BGI/<username>/projects/<project>/"
```

## Common Pitfalls

- **Large files timeout**: Use `rsync --partial` to support resuming interrupted transfers.
- **Permission denied**: Ensure SSH key is 600 permissions.
- **Disk space**: Check with `ssh login_www "df -h /share"` before uploading large datasets.
- **Path confusion**: Remote and local filesystems are separate. Always use absolute paths on the remote side.

## Next Steps

- After uploading data: use `HNAICC_aip_submit` to submit jobs
- Downloading results: logs are at `<project>/logs/`
