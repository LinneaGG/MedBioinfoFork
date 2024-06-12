#Make BLAST index db
zcat /proj/applied_bioinformatics/common_data/refseq_viral_split/* | srun /proj/applied_bioinformatics/tools/ncbi-blast-2.15.0+-src/makeblastdb -dbtype nucl -out ../data/blast_db/ -title SC2_db

# Subset 100, 1000, 10000 reads from merged files
zcat ../merged_pairs/ERR6913116.extendedFrags.fastq.gz | singularity exec ../../../myimage.sif seqkit sample -n 100 -o sample100.fastq.gz --compress-level 1
zcat ../merged_pairs/ERR6913116.extendedFrags.fastq.gz | singularity exec ../../../myimage.sif seqkit sample -n 1000 -o sample1000.fastq.gz --compress-level 1
zcat ../merged_pairs/ERR6913116.extendedFrags.fastq.gz | singularity exec ../../../myimage.sif seqkit sample -n 10000 -o sample10000.fastq.gz --compress-level 1

zcat sample100.fastq.gz | singularity exec ../../../myimage.sif seqkit fq2fa -o sample100.fasta.gz --compress-level 1
..
..


