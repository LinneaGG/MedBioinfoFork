#!/bin/bash
#SBATCH -A naiss2024-22-540
#SBATCH -n 1
#SBATCH --cpus-per-task=2
#SBATCH -t 00:10:00
#SBATCH --array=1-10
#SBATCH -o /proj/applied_bioinformatics/users/x_lingo/MedBioinfoFork/analyses/kraken2_out/slurm.%A.%a.out   # standard output (STDOUT) redirected to these files (with Job ID and array ID in file names)
#SBATCH -e /proj/applied_bioinformatics/users/x_lingo/MedBioinfoFork/analyses/kraken2_out/slurm.%A.%a.err

workdir="/proj/applied_bioinformatics/users/x_lingo/MedBioinfoFork/analyses/krona"
datadir="/proj/applied_bioinformatics/users/x_lingo/MedBioinfoFork/analyses/kraken2"
accnum_file="/proj/applied_bioinformatics/users/x_lingo/MedBioinfoFork/analyses/x_lingo_run_accessions.txt"

cd ${workdir}

accnum=$(sed -n "$SLURM_ARRAY_TASK_ID"p ${accnum_file})
input_file="${datadir}/bracken_report_${SLURM_ARRAY_TASK_ID}_${accnum}"

python /proj/applied_bioinformatics/tools/KrakenTools/kreport2krona.py -r ${input_file} -o "krona_${accnum}.out"

sed -i 's/.__//g' "krona_${accnum}.out"

singularity exec -B /proj:/proj/ /proj/applied_bioinformatics/common_data/kraken2.sif ktImportText "krona_${accnum}.out" -o "krona_${accnum}.out.html"
