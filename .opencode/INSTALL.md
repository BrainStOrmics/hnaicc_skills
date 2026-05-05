# HNAICC Submit -- OpenCode Installation

## Install

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

Or clone this repo and point OpenCode to the SKILL.md:

```bash
git clone https://github.com/xinqi-sleep/HNAICC-skill.git
```

Then tell OpenCode: "Load the skill from HNAICC-skill/skills/HNAICC_submit/SKILL.md"

## Quick Reference

The skill covers:
1. SSH connection to HNAICC cluster (phssh.hnaicc.cn:13310)
2. AIP environment loading (source /opt/skyformai/etc/aip.sh)
3. Job script creation with #CSUB parameters
4. Single and batch job submission via csub
5. Queue management and monitoring
6. Common failure modes and troubleshooting

See SKILL.md for the complete guide.
