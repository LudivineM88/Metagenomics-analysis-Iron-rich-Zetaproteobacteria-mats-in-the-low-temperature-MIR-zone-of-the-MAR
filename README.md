# Metagenomics analysis: Iron-rich Zetaproteobacteria mats in the low temperature MIR zone of the Mid-Atlantic Ridge: morphological, taxonomic, and metabolic insights.
Numerous studies have focused on the iron-rich microbial mats of the Lō‘ihi seamount (volcanic influence), but very few studies have documented the Arctic and Atlantic oceans, where microbial mats have formed as a result of intense hydrothermal activity. (Wiersen et al., 1993; Scott et al., 2015; Vander-Roost, 2017, 2018; Mc Allister et al., 2019; Hribovšek et al., 2023; Astroch-Cardona et al., 2023, 2024). Given the limited information available on these mats that formed on old massive sulfide mounds at the MAR, the study of new low-temperature hydrothermal zones offers unprecedented opportunities to deepen our understanding of community diversity and to better characterize their functioning. Therefore, the objective of this study is to characterize the microbial communities of the unexplored low-temperature MIR (LT-MIR) zone, and to compare this diversity and potential functioning across different hydrothermal fields (Arctic and Atlantic oceans). 

<p align="center">
  <img width="413" height="312" alt="image" src="https://github.com/user-attachments/assets/73916004-f75c-47f5-9d8a-d1a29852f244" />
</p>

Figure 1 : Localization and description of iron-rich microbial mats at the MIR zone (TAG, MAR). (A) Bathymetric map representing the localization of the TAG hydrothermal field (modified from Pelleter 2024 by Pelleter). (B) Bathymetric map focused on the MIR site and indicating with a red dot where samples have been collected at the low-temperature subzone C (Modified from Pelleter et al., 2024 by Pelleter). (C) Image of iron-rich microbial mats from the MIR subzone C collected during the BICOSE 3 oceanographic cruise (© Ifremer-Nautile). 


The MIR mound is a LT zone showing several diffuse fluid emissions, associated with orange – yellow fluffy (veil) microbial mats and located at the east of the TAG hydrothermal vent field (Active Mound) (Fig.1) (Peletter et al., 2024). The LT-MIR microbial communities were analyzed combining metabarcoding, metagenomics, and imaging approaches. Due to the abundance of Zetaproteobacteria in these fluffy veil orange-yellowish mats, their taxonomic diversity, functional potential, and morphologies of their iron (oxy)hydroxides fibrils were examined in more details. 

All data analysis were performed using the DATARMOR cluster (https://pcdm.ifremer.fr/Equipement)

# Quality control of raw metagenomic data

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

# Assembly step

Assembly was performed using the metagenomics workflow implemented in Anvi’o (Eren et al., 2021), developed by Alon Shaiber and collaborators. The workflow was run with the default parameters.

Step 1: Creation of the samples.txt file

A samples.txt file was first generated. This tab-delimited table contains the sample name, group assignment, and the paths to the quality-filtered (trimmed) reads. It serves as the main configuration file required to run the Anvi’o metagenomics workflow in its default mode.

Step 2: Execution of the Anvi’o metagenomics workflow

The workflow was then launched using the Anvi’o metagenomics pipeline, which performs read mapping, contig profiling, and the generation of databases required for downstream analyses.

```
#S02_anvio_workflow.pbs

. /appli/bioinfo/anvio/8_dev/env.sh


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




