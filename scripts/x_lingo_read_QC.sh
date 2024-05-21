#!/bin/bash
echo "Downloading fastq sequences"
date
srun --cpus-per-task=8 --time=00:30:00 singularity exec ../myimage.sif xargs -a ./analyses/x_lingo_run_accessions.txt fastq-dump -I --split-files --gzip -O ./data/sra_fastq/ --disable-multithreading
date
echo "Manipulate fastq files with seqkit:"
echo "Print stats"
ls data/sra_fastq/* | singularity exec ../myimage.sif xargs seqkit stats --threads 1
date
echo "Identify duplicate reads" 
ls data/sra_fastq/* | srun --cpus-per-task=4 --time=00:30:00 singularity exec ../myimage.sif xargs seqkit rmdup -D analyses/dupe_files.txt --threads 4 
date
echo "Have the fastq files already been trimmed?"
singularity exec ../myimage.sif seqkit locate -p "AGATCGGAAGAGCACACGTCTGAACTCCAGTCA" -p "AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT" --threads 1
date
echo "Quality control with fastqc"
srun --cpus-per-task=2 --time=00:30:00 singularity exec ../myimage.sif xargs -I{} -a analyses/x_lingo_run_accessions.txt fastqc data/sra_fastq/{}_1.fastq.gz data/sra_fastq/{}_2.fastq.gz -o analyses/fastqc/ --threads 2
# Looks like the quality score is high for all bases, even at the end of reads, and adapters seem to have been trimmed
date
echo "Merging paired-end reads"
srun --cpus-per-task=2 --time=00:30:00 singularity exec ../myimage.sif flash --threads=2 -o ERR6913116 -d data/merged_pairs -z /data/sra_fastq/ERR6913116_1.fastq.gz /data/sra_fastq/ERR6913116_2.fastq.gz 2>&1 | tee -a analyses/x_lingo_flash.log
# Error noted that I should change the --max-overlap (-M) parameter to more than the standard 65 bp
# Percent combined: 89.06% 
echo "Stats of file: "
ls data/merged_pairs/ERR6913116.extendedFrags.fastq.gz | singularity exec ../myimage.sif xargs seqkit stats --threads 1
date
echo "Now do it for all of the reads"
srun --cpus-per-task=2 --time=00:30:00 singularity exec ../myimage.sif xargs -a analyses/x_lingo_run_accessions.txt -I {} flash --threads=2 -o {} -d data/merged_pairs -z -M 100 data/sra_fastq/{}_1.fastq.gz data/sra_fastq/{}_2.fastq.gz 2>&1 | tee -a analyses/x_lingo_flash.log
# The number of base pairs are pretty similar, the number of bps slightly increased after merging, creating some redundance
date
echo "Mapping with bowtie2 to check for PhiX contamination"
# Download sequence 
singularity exec ../myimage.sif efetch -db nuccore -id NC_001422 -format fasta > ./data/reference_seqs/PhiX_NC_001422.fna
# Create indexed database 
srun singularity exec your_image.sif bowtie2-build -f ./data/reference_seqs/PhiX_NC_001422.fna ./data/bowtie2_DBs/PhiX_bowtie2_DB
# Align merged reads against the index DB 
srun --cpus-per-task=8 singularity exec ../myimage.sif bowtie2 -x ./data/bowtie2_DBs/PhiX_bowtie2_DB -U ./data/merged_pairs/ERR*.extendedFrags.fastq.gz -S ./analyses/bowtie/x_lingo_merged2PhiX.sam --threads 8 --no-unal 2>&1 | tee ./analyses/bowtie/x_lingo_bowtie_merged2PhiX.log
# No alignments! 
date
echo "Check for SARS-CoV-2"
# Get sequence:
singularity exec ../myimage.sif efetch -db nuccore -id NC_045512 -format fasta > ./data/reference_seqs/SC2_NC_045512.fna
# Make indexed DB 
srun singularity exec ../myimage.sif bowtie2-build -f ./data/reference_seqs/SC2_NC_045512.fna ./data/bowtie2_DBs/SC2_bowtie2_DB
# Align
srun --cpus-per-task=8 singularity exec ../myimage.sif bowtie2 -x ./data/bowtie2_DBs/SC2_bowtie2_DB -U ./data/merged_pairs/ERR*.extendedFrags.fastq.gz -S ./analyses/bowtie/x_lingo_merged2SC2.sam --threads 8 --no-unal 2>&1 | tee ./analyses/bowtie/x_lingo_bowtie_merged2SC2.log
# 0.1 % aligned! 
date
echo "MultiQC"
srun singularity exec ../myimage.sif multiqc -o analyses --force --title "x_lingo sample sub-set" ./data/merged_pairs/ ./analyses/fastqc/ ./analyses/x_lingo_flash.log ./analyses/bowtie/
date
