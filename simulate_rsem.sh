#!/bin/bash
set -o nounset
#set -o errexit
 
#########################################
#written by Fenglin
#2019-06-09 created
#AIM: to simulate fastq files using RSEM
#########################################

project=$1
patient=$2
sample=$3

### prepare ref files 
$path_to_RSEM/bin/rsem-prepare-reference --gtf knownGene.gtf --bowtie2 --bowtie2-path $bowtie_path/bowtie2-2.2.3 $ref.fa $ref
### call rsem
$path_to_RSEM/bin/rsem-calculate-expression -p 4 --paired-end --bowtie2 --bowtie2-path $bowtie_path/bowtie2-2.2.3 --estimate-rspd --append-names --calc-ci --single-cell-prior --output-genome-bam $fq1 $fq2 $ref $sample
### simulate fastq files using rsem
$path_to_RSEM/bin/rsem-simulate-reads $ref $outDir/$sample.stat/$sample.model $outDir/$sample.isoforms.results 0 2500000 $sample.sim2
