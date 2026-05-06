---
name: HNAICC_env_setup
description: Use when the user mentions setting up software environments on the HNAICC cluster - conda environment creation, module loading, or checking software availability. Do NOT use for job submission (use HNAICC_aip_submit).
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [hnaicc, hpc, cluster, conda, environment, module, software-setup]
    related_skills: [HNAICC_ssh, HNAICC_aip_submit]
---

# HNAICC Env Setup — Software Environment Configuration

## Checklist

1. **Load AIP environment** — `source /opt/skyformai/etc/aip.sh` in every session
2. **Choose environment type** — module for CPU jobs, conda for GPU/AI jobs
3. **Set up environment** — install packages or load modules
4. **Verify** — check software versions and GPU availability (if applicable)

**Don't use for:** SSH setup (use `HNAICC_ssh`), job submission (use `HNAICC_aip_submit`), or file transfer (use `HNAICC_sftp`).

## Environment Types

| Job Type | Approach | Why |
|----------|----------|-----|
| CPU-only (bioinformatics, stats) | `module load` | Pre-built optimized binaries |
| GPU/AI (PyTorch, TensorFlow, etc.) | `conda` | Module + conda conflict on GPU nodes |
| Custom Python/R packages | `conda` | Flexible package management |
| MPI/multi-node | `module load` + `ompi-mpirun` | Cluster MPI via modules |

## Module-Based Setup (CPU Jobs)

### List Available Software

```bash
module avail                # All available modules
module list                 # Currently loaded
module spider <keyword>     # Search for software
```

### Common Modules

```bash
module load openmpi/4.1.3   # MPI for parallel computing
module load samtools/1.17   # Bioinformatics
module load python/3.10     # Python (alternative to conda)
module load R/4.3.0         # R environment
module load gcc/12.2.0      # Compiler toolchain
```

### In `.aip` Script

```bash
source /opt/skyformai/etc/aip.sh
module load samtools/1.17
module load openmpi/4.1.3
export PATH=/opt/skyformai/bin:$PATH

samtools --version
```

## Conda-Based Setup (GPU/AI Jobs)

### Conda Location

```bash
/share/apps/anaconda3/
```

### Create Environment

```bash
source /opt/skyformai/etc/aip.sh
source /share/apps/anaconda3/bin/activate

conda create -n myenv python=3.10 -y
conda activate myenv
conda install pytorch torchvision torchaudio -c pytorch -y
conda install pandas numpy scikit-learn -y
```

### From environment.yml

```bash
conda env create -f environment.yml
```

### In `.aip` Script

```bash
source /opt/skyformai/etc/aip.sh
export PATH=/opt/skyformai/bin:$PATH

source /share/apps/anaconda3/bin/activate
conda activate myenv

# Verify GPU
echo "CUDA available: $(python -c 'import torch; print(torch.cuda.is_available())')"
echo "GPU: $(python -c 'import torch; print(torch.cuda.get_device_name(0))')"

python train.py
```

## GPU Verification

```bash
source /opt/skyformai/etc/aip.sh
source /share/apps/anaconda3/bin/activate
conda activate myenv

nvcc --version
nvidia-smi
python -c "import torch; print(f'PyTorch: {torch.__version__}, CUDA: {torch.version.cuda}')"
```

After job submission, the scheduler sets `CUDA_VISIBLE_DEVICES` automatically:

```bash
env | grep CUDA
echo $CUDA_VISIBLE_DEVICES
```

## Common Pitfalls

- **GPU module/conda conflict**: Never mix `module load` for AI frameworks with `conda activate` on GPU nodes.
- **Conda not activated in script**: Environment must be activated inside the `.aip` script, not just in interactive shell.
- **Wrong conda path**: Use `/share/apps/anaconda3/bin/activate`, not `conda activate` directly.
- **Large conda envs**: Create in `~/.conda/envs/`, not in shared project directories.
- **Missing AIP env before conda**: Always `source /opt/skyformai/etc/aip.sh` before conda activation in `.aip` scripts — GPU jobs need CUDA env vars from AIP.

## Next Steps

- After environment is ready: use `HNAICC_aip_submit` to submit jobs
