---
name: HNAICC_ssh
description: Use when the user mentions connecting to or logging into the HNAICC cluster - configures SSH credentials, verifies key permissions, and tests connectivity. Do NOT use for file transfers (use HNAICC_sftp) or job operations.
version: 2.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [hnaicc, hpc, cluster, ssh, remote-access, credential-setup]
    related_skills: [HNAICC_sftp, HNAICC_project_setup, HNAICC_env_setup, HNAICC_aip_submit, HNAICC_job_monitor, HNAICC_job_logs]
---

# HNAICC SSH — SSH Connection Management

## Checklist

1. **Obtain SSH credentials** — get username, port, and key path from user (parse config or ask)
2. **Verify key permissions** — ensure key file is 600, ~/.ssh is 700
3. **Write or validate SSH config** — ensure `login_www` host entry is correct
4. **Test connection** — verify login node responds with correct hostname and username
5. **Store credentials for workflow** — remember username and remote workdir for subsequent skills

**Don't use for:** Job submission (use `HNAICC_aip_submit`), file transfer (use `HNAICC_sftp`), or job monitoring (use `HNAICC_job_monitor`).

## Credential Collection

### Method A: Parse existing SSH config

Ask the user for their SSH config file path, then:

```bash
grep -A 6 "login_www" <config_path>
```

Extract: `User`, `Port`, `IdentityFile`.

### Method B: Interactive collection

If no config entry exists, ask the user:

1. **Cluster username** (assigned by HNAICC admin)
2. **SSH port** (assigned by HNAICC admin)
3. **SSH key path** (path to the private key file)

### Method C: No credentials yet

If the user has not received credentials from the admin, direct them to contact the HNAICC administrator.

## Step 1: Write SSH Config

Add to `~/.ssh/config`:

```
Host login_www
    HostName phssh.hnaicc.cn
    User <username>
    ForwardAgent yes
    Port <port>
    IdentityFile <key_path>
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

## Step 2: Fix Key Permissions

```bash
chmod 700 ~/.ssh
chmod 600 <key_path>
```

**Common error**: `Permissions 0644 for '~/.ssh/xxx' are too open.` — fix with `chmod 600`.

## Step 3: Test Connection

```bash
ssh login_www "hostname && whoami"
# Expected: ln01n001, <username>
```

If this fails, diagnose the specific error:

| Error | Cause | Fix |
|-------|-------|-----|
| `Permissions 0644 for 'key' are too open` | SSH key permissions too loose | `chmod 600 <key_path>` |
| `Connection refused` | Wrong port or network unreachable | Verify Port in config, check VPN |
| `Permission denied (publickey)` | Wrong key or user | Confirm User and IdentityFile match admin assignment |
| `Could not resolve hostname` | SSH config missing or typo | Run `grep login_www ~/.ssh/config` |

## Step 4: Store Credentials

After successful connection, note these values for use by dependent skills:

| Value | Source | Used By |
|-------|--------|---------|
| SSH host alias | `login_www` (fixed) | All HNAICC skills |
| Cluster username | From config | sftp, project_setup, aip_submit, job_monitor, job_logs |
| Remote workdir | `/share/org/BGI/<username>/` | sftp, project_setup, aip_submit |

## Common Pitfalls

- **Wrong key permissions**: Must be 600.
- **Missing User or Port**: Each user gets unique credentials from the admin.
- **Connection refused**: Verify port and network reachability.
- **Two SSH sessions don't share shell context**: Always combine operations into a single `ssh` command.

## Next Steps

After SSH is configured and tested:
- Set up project directories: use `HNAICC_project_setup` skill
- Transfer files: use `HNAICC_sftp` skill
- Set up environments: use `HNAICC_env_setup` skill
- Submit jobs: use `HNAICC_aip_submit` skill
- Check status: use `HNAICC_job_monitor` skill
- View logs: use `HNAICC_job_logs` skill
