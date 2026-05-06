#!/bin/bash
# ============================================================
# HNAICC Batch Submit from Sample List
# Usage: bash batch_from_list.sh samples.txt
# Sample list format (tab-separated): sample_name fastq_prefix oligo_prefix
# ============================================================

LIST_FILE="${1:-samples.txt}"

if [ ! -f "$LIST_FILE" ]; then
    echo "Error: $LIST_FILE not found"
    exit 1
fi

mkdir -p aip_scripts logs

# Application name: shared across all jobs in this batch (project-level identifier)
APP_NAME="${APP_NAME:-my_project}"

while read -r sample_name fastq_prefix oligo_prefix; do
    [ -z "$sample_name" ] && continue

    AIP_FILE="aip_scripts/${sample_name}.aip"

    cat <<EOF > "$AIP_FILE"
#!/bin/bash
#CSUB -A ${APP_NAME}
#CSUB -J ${APP_NAME}_${sample_name}
#CSUB -q c01
#CSUB -n 16
#CSUB -R rusage[mem=176G]
#CSUB -R span[hosts=1]
#CSUB -o logs/${sample_name}.out
#CSUB -e logs/${sample_name}.err

source /opt/skyformai/etc/aip.sh

echo "Processing: ${sample_name}"
echo "Fastq: ${fastq_prefix}"
echo "Oligo: ${oligo_prefix}"

# Replace with your actual analysis command
# ./run_analysis.sh ${sample_name} ${fastq_prefix} ${oligo_prefix}

echo "Completed: ${sample_name}"
EOF

    chmod +x "$AIP_FILE"
    echo "Submitting: ${sample_name}..."
    csub < "$AIP_FILE"
    sleep 1

done < "$LIST_FILE"

echo ""
echo "All jobs submitted. Check with: cjobs"
