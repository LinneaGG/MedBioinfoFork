#!/bin/bash
#SBATCH -A naiss2024-22-540
#SBATCH -n 1
#SBATCH --cpus-per-task=2
#SBATCH -t 01:00:00
#SBATCH --mem=90GB
#SBATCH --array=1-10
#SBATCH -o /proj/applied_bioinformatics/users/x_lingo/MedBioinfoFork/analyses/kraken2_out/slurm.%A.%a.out   # standard output (STDOUT) redirected to these files (with Job ID and array ID in file names)
#SBATCH -e /proj/applied_bioinformatics/users/x_lingo/MedBioinfoFork/analyses/kraken2_out/slurm.%A.%a.err

workdir="/proj/applied_bioinformatics/users/x_lingo/MedBioinfoFork/analyses/kraken2"
datadir="/proj/applied_bioinformatics/users/x_lingo/MedBioinfoFork/data/sra_fastq"
accnum_file="/proj/applied_bioinformatics/users/x_lingo/MedBioinfoFork/analyses/x_lingo_run_accessions.txt"

cd ${workdir}

accnum=$(sed -n "$SLURM_ARRAY_TASK_ID"p ${accnum_file})
input_file="${datadir}/${accnum}"

# Run kraken2 
srun --job-name="kraken2_${accnum}" singularity exec -B /proj:/proj/ /proj/applied_bioinformatics/common_data/kraken2.sif kraken2 --db /proj/applied_bioinformatics/common_data/kraken_database --threads ${SLURM_CPUS_PER_TASK} --paired --gzip-compressed --output "kraken_${SLURM_ARRAY_TASK_ID}_${accnum}.out" --report "kraken_report_${SLURM_ARRAY_TASK_ID}_${accnum}" "${input_file}_1.fastq.gz" "${input_file}_2.fastq.gz"

# Run bracken 
srun --job-name="bracken_${accnum}" singularity exec -B /proj:/proj/ /proj/applied_bioinformatics/common_data/kraken2.sif bracken -d /proj/applied_bioinformatics/common_data/kraken_database -i "kraken_report_${SLURM_ARRAY_TASK_ID}_${accnum}" -o "bracken_${SLURM_ARRAY_TASK_ID}_${accnum}.out" -w "bracken_report_${SLURM_ARRAY_TASK_ID}_${accnum}"

sacct -P --format=JobID%15,JobName%18,ReqCPUS,ReqMem,Timelimit,State,ExitCode,Start,elapsedRAW,CPUTimeRAW,MaxRSS,NodeList  -j ${SLURM_JOB_ID} grep ERR >> "${workdir}/kraken2_vs_viral.sacct"
