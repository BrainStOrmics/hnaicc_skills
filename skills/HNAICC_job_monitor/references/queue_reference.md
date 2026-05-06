# HNAICC Queue Reference

## Cluster Architecture (Verified 2026-05-05)

- **AIP Version**: 10.25.0
- **Master Node**: s01n003 (cadmin)
- **Total Nodes**: 1,076
- **Login Node**: ln01n001 (SSH entry point)
- **Default Work Dir**: /share/org/BGI/<username>/

## Node Types

### s01 Series (Standard Compute)
- Cores: 48
- Memory: 512 GB
- Nodes: s01n001, s01n002, s01n003

### c01 Series (High-Memory Compute, Primary)
- CPUs: 2x Intel 8458P
- Cores: 88 per node
- Memory: 1 TB
- Network: NDR 200G
- Nodes: c01n0001 - c01n0036+ (1000+ nodes)
- **Memory allocation: 11GB per core (fixed)**

## Queue Details

### c01 (Primary Queue)
- **Status**: OK
- **Available**: 41,536 slots (varies)
- **Running**: ~10,195 jobs
- **Core limits**: 1,2,4,8,16,32,44,64,88,176,264,352,440...
- **Scheduling**: FAIRSHARE + EXCLUSIVE
- **Per-core memory**: 11GB (jobs exceeding this are killed)
- **Use case**: General bioinformatics analysis

### c02
- **Status**: OK
- **Available**: 11,000 slots
- **Running**: ~417 jobs
- **Use case**: Secondary compute queue

### gpu_100 (A100)
- **Available**: 640 slots, ~240 running
- **GPU-CPU ratio**: 6 cores = 1 A100 GPU
- **Use case**: AI/Deep Learning

### g02
- **Available**: 640 slots, ~240 running
- **Use case**: General GPU computing

### g21
- **Available**: 128 slots, ~80 running
- **Use case**: GPU computing

### c01_bgi
- **Available**: 88 slots, ~3 running
- **Use case**: Restricted BGI access

### c01_gtx
- **Available**: 35,904 slots, ~48 running
- **Use case**: GTX GPU computing

### www
- **Available**: 300 slots, ~204 running
- **Use case**: Web services

### login
- **Available**: 2,552 slots, ~1,483 running
- **Use case**: Login node tasks

## Memory Calculation Examples (c01 Queue)

| Cores (-n) | Memory (rusage) | Use Case |
|------------|-----------------|----------|
| 2 | 22G | Quick tests, small scripts |
| 4 | 44G | Small analyses |
| 8 | 88G | Medium analyses |
| 16 | 176G | Standard scRNA-seq |
| 32 | 352G | Large batch processing |
| 44 | 484G | Very large datasets |
| 64 | 704G | Genome assembly |
| 88 | 968G | Maximum single node |

## Commands Reference

```bash
# Cluster inspection
aip cluster info        # All nodes overview
aip host info           # Host load summary
aip host info <host>    # Specific host
aip host res            # Resource details
aip host res <host>     # Specific host resources
aip queue info          # Queue status
aip j i -p <jobid>      # Job resource utilization

# Job management
csub < job.aip          # Submit
cjobs                   # List jobs
cjobs -w <jobid>        # Specific job (any status)
ckill <jobid>           # Kill
cstop <jobid>           # Pause
cresume <jobid>         # Resume
ctop <jobid>            # Highest priority
cbot <jobid>            # Lowest priority
cswitch                 # Switch queue
man csub                # Full manual
```

## Environment

```bash
# Load AIP (must be done first)
source /opt/skyformai/etc/aip.sh

# Sets these variables:
# CB_ENVDIR=/opt/skyformai/etc
# LSF_ENVDIR=/opt/skyformai/etc
# LSF_SERVERDIR=/opt/skyformai/sbin
# LSF_BINDIR=/opt/skyformai/bin
# PATH includes /opt/skyformai/bin
# MANPATH includes /opt/skyformai/share/man
```
