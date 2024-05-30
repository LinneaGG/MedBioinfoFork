
cd /proj/applied_bioinformatics/users/x_lingo/MedBioinfoFork

srun singularity exec ../myimage.sif multiqc -o analyses --force --title "x_lingo sample sub-set" ./data/merged_pairs/ ./analyses/fastqc/ ./analyses/x_lingo_flash.log ./analyses/bowtie/ ./analyses/kraken2
