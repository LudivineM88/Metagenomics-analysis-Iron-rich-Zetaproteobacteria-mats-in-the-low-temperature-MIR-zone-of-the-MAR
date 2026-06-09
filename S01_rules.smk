#!/usr/bin/env python
from snakemake.shell import shell
from os.path import join
shell.executable("/bin/bash")
#set the workdir
workdir:config["workdir"]

datadir=config["datadir"]
SAMPLES, = glob_wildcards(join(datadir, "{sample}_R1.fastq.gz"))

# Patterns for the 1st mate and the 2nd mate using the 'sample' wildcard. Snakemake regular expression matching the forward mate FASTQ files.
PATTERN_R1 = '{sample}_R1.fastq.gz'
PATTERN_R2 = '{sample}_R2.fastq.gz'

rule all:
    input:
        "01_QC/multiqc/multiqc_report.html",
        "01_QC/multiqc_trimmed/multiqc_report.html"

rule fastqc:
    input: 
        r1 = join(datadir, PATTERN_R1),
        r2 = join(datadir, PATTERN_R2)
    output:
        "01_QC/fastqc/{sample}_R1_fastqc.html",
        "01_QC/fastqc/{sample}_R1_fastqc.zip"
    params:
        out="01_QC/fastqc"
    resources:
        ncpus=config["fastqc"]["ncpus"]
    log:
        "00_LOGS/fastqc_{sample}.log"
    run:
        shell("set +u ;"
                ". /appli/bioinfo/fastqc/0.11.9/env.sh ; "
                "fastqc -t {resources.ncpus} {input.r1} {input.r2} -o {params.out} >> {log} 2>&1 ; "
                ". /appli/bioinfo/fastqc/0.11.9/delenv.sh ; "
                "set -u " )

rule multiqc:
    input : 
        expand("01_QC/fastqc/{sample}_R1_fastqc.html", sample=SAMPLES),
        expand("01_QC/fastqc/{sample}_R1_fastqc.zip", sample=SAMPLES)
    output : 
        "01_QC/multiqc/multiqc_report.html"
    params:
        indir="01_QC/fastqc",
        outdir="01_QC/multiqc"
    log:
        "00_LOGS/multiqc.log"
    run:
        shell("set +u ;"
              ". /appli/bioinfo/multiqc/1.15/env.sh ; "
              "multiqc {params.indir} -o {params.outdir} >> {log} 2>&1 ; "
              "set -u " )

rule wget:
    input:
        expand("01_QC/fastqc/{sample}_R1_fastqc.html", sample=SAMPLES),
        expand("01_QC/fastqc/{sample}_R1_fastqc.zip", sample=SAMPLES)
    output:
        "01_QC/bbduk/truseq.fa.gz"
    params:
        ref="01_QC/bbduk"
    log:
        "00_LOGS/wget.log"
    run:
        shell("set +u ;"
              "wget https://github.com/BioInfoTools/BBMap/raw/master/resources/truseq.fa.gz -P {params.ref} >> {log} 2>&1 ; "
              "set -u " )

rule bbduk:
    input:
        r1 = join(datadir, PATTERN_R1),
        r2 = join(datadir, PATTERN_R2),
        ref="01_QC/bbduk/truseq.fa.gz"
    output:
        r1="01_QC/bbduk/{sample}_trimmed_R1.fastq.gz",
        r2="01_QC/bbduk/{sample}_trimmed_R2.fastq.gz"
    params:
        stats="01_QC/bbduk/{sample}_stats.txt"
    resources:
        ncpus=config["bbduk"]["ncpus"]
    log:
        "00_LOGS/bbduk_{sample}.log"
    run:
        shell("set +u ;"
              ". /appli/bioinfo/bbmap/38.57/env.sh ; "
              "bbduk.sh in1={input.r1} in2={input.r2} out1={output.r1} out2={output.r2} ref={input.ref} stats={params.stats} ktrim=r k=23 mink=11 hdist=1 tpe tbo mlf=0.75 t=8 >> {log} 2>&1 ; "
              "set -u ")

rule fastqc_trimmed:
    input:
        r1="01_QC/bbduk/{sample}_trimmed_R1.fastq.gz",
        r2="01_QC/bbduk/{sample}_trimmed_R2.fastq.gz"    
    output:
        "01_QC/fastqc_trimmed/{sample}_trimmed_R1_fastqc.html",
        "01_QC/fastqc_trimmed/{sample}_trimmed_R1_fastqc.zip"
    params:
        out="01_QC/fastqc_trimmed"
    resources:
        ncpus=config["fastqc_trimmed"]["ncpus"]
    log:
        "00_LOGS/fastqc_trimmed_{sample}.log"
    run:
        shell("set +u ;"
                ". /appli/bioinfo/fastqc/0.11.9/env.sh ; "
                "fastqc -t {resources.ncpus} {input.r1} {input.r2} -o {params.out} >> {log} 2>&1 ; "
                ". /appli/bioinfo/fastqc/0.11.9/delenv.sh ; "
                "set -u " )

rule multiqc_trimmed:
    input :
        expand("01_QC/fastqc_trimmed/{sample}_trimmed_R1_fastqc.html", sample=SAMPLES),
        expand("01_QC/fastqc_trimmed/{sample}_trimmed_R1_fastqc.zip", sample=SAMPLES)
    output :
        "01_QC/multiqc_trimmed/multiqc_report.html"
    params:
        indir="01_QC/fastqc_trimmed",
        outdir="01_QC/multiqc_trimmed"
    log:
        "00_LOGS/multiqc_trimmed.log"
    run:
        shell("set +u ;"
              ". /appli/bioinfo/multiqc/1.15/env.sh ; "
              "multiqc {params.indir} -o {params.outdir} >> {log} 2>&1 ; "
              "set -u " )


onsuccess:
    print("Workflow finished, no error")

onerror:
    print("An error occured")
