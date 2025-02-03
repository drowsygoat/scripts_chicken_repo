#!/bin/bash

# make reference for multiome
# soft masked fasta used

# MODULE PARAMETERS
RUN_COMMAND="run_shell_command.sh"
JOB_NAME="mkref"
PARTITION="main"
NODES=1
TIME="23:05:00"
TASKS=1
CPUS=1
DRY="no"

if [ -d "$JOB_NAME" ]; then
    echo "Error: Directory $JOB_NAME already exists." >&2
    exit 1
else
    mkdir -p "$JOB_NAME"
fi


GTF="/cfs/klemming/projects/snic/sllstore2017078/lech/sarek/refs/112/gtf/Gallus_gallus.bGalGal1.mat.broiler.GRCg7b.112.gtf.gz"

FASTA="/cfs/klemming/projects/snic/sllstore2017078/lech/sarek/refs/112/genome/Gallus_gallus.bGalGal1.mat.broiler.GRCg7b.dna_sm.toplevel.fa.gz"

CONFIG="/cfs/klemming/projects/snic/sllstore2017078/lech/RR/scAnalysis/single_cell_gal7b/mkref/gal7b_config"

PREPARED_GTF="prepared.gtf"

UNZIPPED="${FASTA%.gz}"

# this keeps the gzipped file, -c directs to stdout
if [ ! -f "$UNZIPPED" ]; then
    unpigz -c "$FASTA" > "$UNZIPPED"
fi

cat <<EOF > "$CONFIG"
{
    organism: "chicken"
    genome: ["bGalGal1_mat_broiler_GRCg7b"]
    input_fasta: ["${UNZIPPED}"]
    input_gtf: ["${PREPARED_GTF}"]
    non_nuclear_contigs: ["MT"]
    input_motifs: "/cfs/klemming/projects/snic/sllstore2017078/scRNAseq/BackUp_CellRanger_VKumarMay10/Used_Cell_Ranger_Genome_Anno/jaspar_formatted.txt"
}
EOF

process_file() {
    local input=$1
    local output=$2

    echo "Input: $input"
    echo "Output: $output"

    export input output

    $RUN_COMMAND -J "$JOB_NAME" -p "$PARTITION" -n "$TASKS" -t "$TIME" -N "$NODES" -c "$CPUS" -d "$DRY" \
    'cellranger-arc mkref --config=$input --nthreads=10'
}

cd  "$JOB_NAME"
cellranger-arc mkgtf $GTF $PREPARED_GTF
process_file $CONFIG 