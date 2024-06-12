#!/bin/bash
#SBATCH -A naiss2024-22-540
#SBATCH -n 1
#SBATCH --cpus-per-task=1
#SBATCH -t 01:00:00
#SBATCH --mem=90GB
#SBATCH -o /proj/applied_bioinformatics/users/x_lingo/MedBioinfoFork/analyses/kraken2_out/slurm.%A.%a.out   # standard output (STDOUT) redirected to these files (with Job ID and array ID in file names)
#SBATCH -e /proj/applied_bioinformatics/users/x_lingo/MedBioinfoFork/analyses/kraken2_out/slurm.%A.%a.err

# Run kraken2 
srun --job-name=kraken2 singularity exec -B /proj:/proj/ /proj/applied_bioinformatics/common_data/kraken2.sif kraken2 --db /proj/applied_bioinformatics/common_data/kraken_database --threads 1 --paired --gzip-compressed --output /proj/applied_bioinformatics/users/x_lingo/MedBioinfoFork/analyses/kraken2/kraken.out --report /proj/applied_bioinformatics/users/x_lingo/MedBioinfoFork/analyses/kraken2/kraken_report /proj/applied_bioinformatics/users/x_lingo/MedBioinfoFork/data/sra_fastq/ERR6913232_1.fastq.gz /proj/applied_bioinformatics/users/x_lingo/MedBioinfoFork/data/sra_fastq/ERR6913232_2.fastq.gz

# Run bracken 
srun --job-name=bracken singularity exec -B /proj:/proj/ /proj/applied_bioinformatics/common_data/kraken2.sif bracken -d /proj/applied_bioinformatics/common_data/kraken_database -i /proj/applied_bioinformatics/users/x_lingo/MedBioinfoFork/analyses/kraken2/kraken_report -o /proj/applied_bioinformatics/users/x_lingo/MedBioinfoFork/analyses/kraken2/bracken.out -w /proj/applied_bioinformatics/users/x_lingo/MedBioinfoFork/analyses/kraken2/bracken_report
