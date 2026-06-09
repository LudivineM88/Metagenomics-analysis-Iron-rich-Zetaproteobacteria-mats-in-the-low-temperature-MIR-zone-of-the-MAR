# Metagenomics analysis: Iron-rich Zetaproteobacteria mats in the low temperature MIR zone of the Mid-Atlantic Ridge: morphological, taxonomic, and metabolic insights.
Numerous studies have focused on the iron-rich microbial mats of the Lō‘ihi seamount (volcanic influence), but very few studies have documented the Arctic and Atlantic oceans, where microbial mats have formed as a result of intense hydrothermal activity. (Wiersen et al., 1993; Scott et al., 2015; Vander-Roost, 2017, 2018; Mc Allister et al., 2019; Hribovšek et al., 2023; Astroch-Cardona et al., 2023, 2024). Given the limited information available on these mats that formed on old massive sulfide mounds at the MAR, the study of new low-temperature hydrothermal zones offers unprecedented opportunities to deepen our understanding of community diversity and to better characterize their functioning. Therefore, the objective of this study is to characterize the microbial communities of the unexplored low-temperature MIR (LT-MIR) zone, and to compare this diversity and potential functioning across different hydrothermal fields (Arctic and Atlantic oceans). 

<p align="center">
  <img width="413" height="312" alt="image" src="https://github.com/user-attachments/assets/73916004-f75c-47f5-9d8a-d1a29852f244" />
</p>

Figure 1 : Localization and description of iron-rich microbial mats at the MIR zone (TAG, MAR). (A) Bathymetric map representing the localization of the TAG hydrothermal field (modified from Pelleter 2024 by Pelleter). (B) Bathymetric map focused on the MIR site and indicating with a red dot where samples have been collected at the low-temperature subzone C (Modified from Pelleter et al., 2024 by Pelleter). (C) Image of iron-rich microbial mats from the MIR subzone C collected during the BICOSE 3 oceanographic cruise (© Ifremer-Nautile). 


The MIR mound is a LT zone showing several diffuse fluid emissions, associated with orange – yellow fluffy (veil) microbial mats and located at the east of the TAG hydrothermal vent field (Active Mound) (Fig.1) (Peletter et al., 2024). The LT-MIR microbial communities were analyzed combining metabarcoding, metagenomics, and imaging approaches. Due to the abundance of Zetaproteobacteria in these fluffy veil orange-yellowish mats, their taxonomic diversity, functional potential, and morphologies of their iron (oxy)hydroxides fibrils were examined in more details. 

All data analysis were performed using the DATARMOR cluster (https://pcdm.ifremer.fr/Equipement)

# 1. MAGs formation
## 1.1 Quality control of raw metagenomic data

Read quality assessment and adapter trimming were first conducted using FastQC, MultiQC, and BBDuk. These analyses were implemented through a Snakemake workflow developed by J. Aubé, a bioinformatics engineer at the laboratory, ensuring a standardized and reproducible preprocessing pipeline.

```
#S01_snakemake.pbs

. /path/to/snakemake/6.6.0/env.sh

TIMESTAMP=$(date +%Y-%m-%d_%Hh%Mm%Ss)
LOG="S01_snakemake"_"$TIMESTAMP"".log"

SF=Path/to/script

snakemake $@ --verbose --cluster-config $SF/S01_cluster.yml --configfile $SF/S01_cluster.yml -p --jobs 30 --cluster "qsub -S '/bin/bash' -N {rule} -m n -q {cluster.queue} -l ncpus={cluster.ncpus} -l walltime={cluster.walltime} -l mem={cluster.memory}" --latency-wait 420 -s $SF/S01_rules.smk --rerun-incomplete --reason >> $SF/$LOG 2>&1
```

Rule files for clusters and Snakemake are also available under the names S01_cmuster.yml and S01_rules.smk

## 1.2 Assembly step

Assembly was performed using the metagenomics workflow implemented in Anvi’o (Eren et al., 2021), developed by Alon Shaiber and collaborators. The workflow was run with the default parameters.

Step 1: Creation of the samples.txt file

A samples.txt file was first generated. This tab-delimited table contains the sample name, group assignment, and the paths to the quality-filtered (trimmed) reads. It serves as the main configuration file required to run the Anvi’o metagenomics workflow in its default mode.

Step 2: Execution of the Anvi’o metagenomics workflow

The workflow was then launched using the Anvi’o metagenomics pipeline, which performs read mapping, contig profiling, and the generation of databases required for downstream analyses.

```
#S02_anvio_workflow.pbs

. /path/to/anvio/8_dev/env.sh


TIMESTAMP=$(date +%Y-%m-%d_%Hh%Mm%Ss)
LOG="S40_anvi_workflow"_"$TIMESTAMP"".log"

cd /path/to/02_anvio

anvi-run-workflow -w metagenomics \
                  -c /path/to/02_anvio/metagenomic_config.json \
                  --additional-params \
                      --directory /path/to/02_anvio \
                      --jobs 30 \
                      --rerun-triggers mtime \
                      --latency-wait 420 \
                      --cluster-config /path/to/02_anvio/cluster.yml \
                      --cluster \
                          "qsub -N {rule} \
                                -m n \
                                -q {cluster.queue} \
                                -l walltime={cluster.walltime} \
                                -l mem={cluster.memory} \
                                -l ncpus={threads} \
                                -V" >> $HOME/script/$LOG 2>&1

```

The required files can be found under the names samples.txt, cluster.yml and metagenomic_config.json

## 1.3 Binning step 

We decided to use BASALT, an automated binning tool that integrates multiple binning algorithms to improve genome recovery. To run BASALT, symbolic links were first created in the directory 02_ANVIO/07_BASALT, pointing to the assembly files located in 02_ANVIO/02_FASTA/ and to the quality-filtered short reads stored in 02_ANVIO/01_QC/ (both R1 and R2 files).

```
#S03_basalt.pbs

. /path/to/basalt/1.0.0/env.sh


# BASALT does not support absolute path as input. We need to create soft links to our working directory.

cd /path/to/07_basalt

BASALT -a MIR-contigs-prefix-formatted-only.fa \
       -s PBT3_F-QUALITY_PASSED_R1.fastq.gz,PBT3_F-QUALITY_PASSED_R2.fastq.gz/PBT3_S-QUALITY_PASSED_R1.fastq.gz,PBT3_S-QUALITY_PASSED_R2.fastq.gz/PBT-QUALITY_PASSED_R1.fastq.gz,PBT-QUALITY_PASSED_R2.fastq.gz/PL4_F-QUALITY_PASSED_R1.fastq.gz,PL4_F-QUALITY_PASSED_R2.fastq.gz/PL4_S-QUALITY_PASSED_R1.fastq.gz,PL4_S-QUALITY_PASSED_R2.fastq.gz/PL6_F-QUALITY_PASSED_R1.fastq.gz,PL6_F-QUALITY_PASSED_R2.fastq.gz/PL6_S-QUALITY_PASSED_R1.fastq.gz,PL6_S-QUALITY_PASSED_R2.fastq.gz/T1-QUALITY_PASSED_R1.fastq.gz,T1-QUALITY_PASSED_R2.fastq.gz\
       --autopara more-sensitive \
       -t ${NCPUS} -m 300 >> ../00_LOGS/basalt.log 2>&1

```
# 2. Quality check and taxonomic assignation
## 2.1 Quality check

The step for selecting MAGs based on completeness and redundancy was carried out using the CheckM2 tool.

```
#S04_checkm2.pbs
# Load Singularity
. /etc/profile.d/modules.sh
module purge
module load singularity/3.4.1

# Load Checkm2 environment
. /path/to/checkm2/1.0.1/env.sh

# Checkm2 singularity container
CHECKM2_SIF=/path/to/checkm2/1.0.1/checkm2-1.0.1.sif

workdir=$(/path/to/03_MAGs)
outdir=$("$workdir"/checkm2_output)
input=$("$workdir"/bins)

cd $workdir
#Run Checkm2
singularity run -B /appli -B /path/to/checkm2/1.0.1/ -B $DATAWORK ${CHECKM2_SIF} checkm2 predict --input $input -x fa --threads 6 --output-directory $outdir >& $workdir/checkm2_test.log 2>&1  
  
```

The quality filter was set to a completion rate of over 70% and a redundancy rate of less than 5% for the retained MAGs.

## 2.2 Taxonomic assignation

Taxonomic affiliation was carried out with the GTDB-Tk tool using the GTDB database (v.2.7.0 (R232))

```
#S05_gtdbtk.pbs
. /path/to/gtdbtk/2.7.0/env.sh

cd /path/to/03_MAGs


gtdbtk classify_wf --cpus 33 --genome_dir MAGs --skip_ani_screen -x fa --out_dir taxonomy/classify_wf_output_gtdbtk >> ../LOGS/MAGs_gtdbtk.log 2>&1

```

# 3. Reformatted Fasta files

The Fasta files were reformatted using the command line `anvi-script-reformat-fasta` in Anvio'8.

```
# S08_reformat.pbs
# Load tool : path to the tool
. /path/to/anvio/8_dev/env.sh

# Path to working directory
cd /path/to/04_MAGs

# Reformat fasta files : in fasta file, replace bin name by the rename bin name (script S01)
for i in MAGs_SELECTED/*.fa
do 
name=$(basename "$i")
prefix=$(echo "$name"|cut -f1 -d '_')

anvi-script-reformat-fasta $i -o NCBI/MIR_"$prefix".fasta --prefix $prefix --simplify-names -r NCBI.txt
done >> ../00_LOGS/${PBS_JOBNAME}.log 2>&1

```
# 4. Mapping (read recruitment)

This step allows us to assess the relative abundance of the recovered bins across all samples. For this purpose, we use the Anvi'o metagenomics workflow in reference mode, following the pipeline described previously. The analysis generates an anvi'o collection and a comprehensive summary reporting MAG relative abundance, detection, and the presence of single-copy core genes (SCGs) and ribosomal genes. Furthermore, it provides a framework for visualizing the bins produced by Basalt and refining them when required.

```
#S09_mapping.pbs
. /path/to/anvio/8_dev/env.sh

TIMESTAMP=$(date +%Y-%m-%d_%Hh%Mm%Ss)
LOG="S08_mapping"_"$TIMESTAMP"".log"

cd /path/to/06_MAPPING

anvi-run-workflow -w metagenomics \
                  -c /path/to/config.json \
                  --additional-params \
                      --directory /hpath/to/06_MAPPING \
                      --jobs 20 \
                      --latency-wait 420 \
                      --cluster-config /path/to/cluster.yml \
		      --rerun-triggers mtime \
                      --cluster \
                          "qsub -N {rule} \
                                -m n \
                                -q {cluster.queue} \
                                -l walltime={cluster.walltime} \
                                -l mem={cluster.memory} \
                                -l ncpus={threads} \
                                -V" >> /path/to/00_LOGS/$LOG 2>&1

```

# 5. HMM 
## 5.1 Construction of the HMM profile _grcJ_ 

HMM profile for the _grcJ_ gene, identified as a potential new marker of iron oxidation (Barco et al., 2025), was created and used with the HMMER tool (v.3.3.2) (Eddy et al., 2023). First, the amino acid sequence from Barco et al. (2024) was retrieved and entered into the NCBI database (WP_051937832.1) in order to obtain other _grcJ_ sequences. Hits with an e-value lower than 1.0×10<sup>-50</sup> were conserved and aligned with multiple alignment program for amino acid or nucleotide sequences (v7) (MAFFT). The HMM profile of _grcJ_ was built with hmmbuild (default parameter) (DOI: 10.5281/zenodo.19659629). 

```
hmmbuild grcJ.hmm grcJ_alignement.fasta 
```

## 5.2 HMM profile searches

All HMM profile searches for all MAGs were based on Prokka prediction with a threshold value of 1.0×10<sup>-30</sup> using HMMER tool

```
#S13_HMM.pbs
cd 05_ANNOTATION
# Do the HMM search from .faa (prokka output)
for ID in prokka/*/*.faa
    do
    name=$(basename $ID .faa)
    hmmsearch ../09_HMM/grcJ.hmm $ID
done
```

# 6. Metabolic overview 
## 6.1 Fegenie


## 6.2 METABOLIC

# 7. Phylogenomic tree 



