#!/bin/bash
# ============================================================
# HNAICC Batch Submit from ID Array
# Usage: bash batch_from_array.sh
# Modify the id_list array below with your IDs
# ============================================================

id_list=(
    "SAMPLE001"
    "SAMPLE002"
    "SAMPLE003"
)

if [ ! -f "process.py" ]; then
    echo "Error: process.py not found"
    exit 1
fi

mkdir -p aip_scripts logs

echo "Submitting ${#id_list[@]} jobs..."

for id in "${id_list[@]}"; do
    AIP_FILE="aip_scripts/job_${id}.aip"

    cat <<EOF > "$AIP_FILE"
#!/bin/bash
#CSUB -J job_${id}
#CSUB -q c01
#CSUB -n 32
#CSUB -R rusage[mem=352G]
#CSUB -R span[hosts=1]
#CSUB -o logs/${id}.out
#CSUB -e logs/${id}.err

source /opt/skyformai/etc/aip.sh

echo "Starting: $(date) | ID: ${id}"

# Activate environment and run
# conda activate myenv
python3 process.py ${id}

if [ \$? -eq 0 ]; then
    echo "SUCCESS: $(date) | ${id}"
else
    echo "FAILED: $(date) | ${id}"
    exit 1
fi
EOF

    chmod +x "$AIP_FILE"
    echo "  Submitting: ${id}"
    csub < "$AIP_FILE"
    sleep 1
done

echo "Done! ${#id_list[@]} jobs submitted."
echo "Check status: cjobs"
echo "View logs: tail -f logs/SAMPLE001.out"
