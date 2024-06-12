#!/bin/bash
#
#SBATCH --ntasks=1                   # nb of *tasks* to be run in // (usually 1), this task can be multithreaded (see cpus-per-task)
#SBATCH --nodes=1                    # nb of nodes to reserve for each task (usually 1)
#SBATCH --cpus-per-task=12            # nb of cpu (in fact cores) to reserve for each task /!\ job killed if commands below use more cores
#SBATCH --mem=250GB                  # amount of RAM to reserve for the tasks /!\ job killed if commands below use more RAM
#SBATCH --time=0-02:00               # maximal wall clock duration (D-HH:MM) /!\ job killed if commands below take more time than reservation
#SBATCH -o /proj/applied_bioinformatics/users/x_lingo/MedBioinfoFork/analyses/blastn_out/slurm.%A.%a.out   # standard output (STDOUT) redirected to these files (with Job ID and array ID in file names)
#SBATCH -e /proj/applied_bioinformatics/users/x_lingo/MedBioinfoFork/analyses/blastn_out/slurm.%A.%a.err   # standard error  (STDERR) redirected to these files (with Job ID and array ID in file names)
# /!\ Note that the ./outputs/ dir above needs to exist in the dir where script is submitted **prior** to submitting this script
#SBATCH --array=1-10                # 1-N: clone this script in an array of N tasks: $SLURM_ARRAY_TASK_ID will take the value of 1,2,...,N
#SBATCH --job-name=MedBioinfo        # name of the task as displayed in squeue & sacc, also encouraged as srun optional parameter
#SBATCH --mail-type END              # when to send an email notiification (END = when the whole sbatch array is finished)
#SBATCH --mail-user linnea.good@uu.se

#################################################################
# Preparing work (cd to working dir, get hold of input data, convert/un-compress input data when needed etc.)
workdir="/proj/applied_bioinformatics/users/x_lingo/MedBioinfoFork/analyses/blastn"
datadir="/proj/applied_bioinformatics/users/x_lingo/MedBioinfoFork/data/merged_pairs"
accnum_file="/proj/applied_bioinformatics/users/x_lingo/MedBioinfoFork/analyses/x_lingo_run_accessions.txt"

echo START: `date`

mkdir -p ${workdir}      # -p because it creates all required dir levels **and** doesn't throw an error if the dir exists :)
cd ${workdir}
mkdir -p temp

# this extracts the item number $SLURM_ARRAY_TASK_ID from the file of accnums
accnum=$(sed -n "$SLURM_ARRAY_TASK_ID"p ${accnum_file})
input_file="${datadir}/${accnum}.extendedFrags.fastq.gz"
# alternatively, just extract the input file as the item number $SLURM_ARRAY_TASK_ID in the data dir listing
# this alternative is less handy since we don't get hold of the isolated "accnum", which is very handy to name the srun step below :)
# input_file=$(ls "${datadir}/*.fastq" | sed -n ${SLURM_ARRAY_TASK_ID}p)

# Convert from fastq to fasta
zcat ${input_file} | singularity exec ../../../myimage.sif seqkit fq2fa -o ./temp/${accnum}.fasta

conv_input_file="${workdir}/temp/${accnum}.fasta"

# because there are mutliple jobs running in // each output file needs to be made unique by post-fixing with $SLURM_ARRAY_TASK_ID and/or $accnum
output_file="${workdir}/blastn_SC2.${accnum}.out"

#################################################################
# Start work
# add -evalue and -perc_identity so that I get some hits
srun --job-name=${accnum} /proj/applied_bioinformatics/tools/ncbi-blast-2.15.0+-src/blastn -num_threads ${SLURM_CPUS_PER_TASK} -query ${conv_input_file} -db /proj/applied_bioinformatics/users/x_lingo/MedBioinfoFork/data/blast_db/blastn -outfmt "6 qaccver saccver pident length mismatch gapopen qstart qend sstart send evalue bitscore" -out ${output_file} -evalue 100 -perc_identity 50

#################################################################
# Clean up (eg delete temp files, compress output, recompress input etc)
#srun gzip ${input_file}
#rm ${workdir}/temp/${accnum}.fasta.gz
srun gzip ${output_file}
srun gzip ${conv_input_file}
echo END: `date`
