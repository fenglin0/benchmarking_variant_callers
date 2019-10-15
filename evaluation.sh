#!/bin/bash
set -o nounset
#set -o errexit
 
#########################################
#written by Fenglin
#2019-03-27 created
#AIM:
#USAGE:
#########################################

project=$1
patient=$2
sample=$3
pipe=$4 

n=50000

#rtg format -o $faDir/random_${n}_sites_conf.sdf $faDir/random_${n}_sites_conf.fa

if [ ! -f $faDir/random_${n}_sites_conf_reverse.vcf.gz ]; then
    cat <(cat $faDir/random_${n}_sites_conf.vcf|grep "#") <(cat $faDir/random_${n}_sites_conf.vcf|grep -v "#"|awk '{print $1,$2,$3,$5,$4,$6,$7,$8}' OFS='\t') > $faDir/random_${n}_sites_conf_reverse.vcf
    bgzip -f $faDir/random_${n}_sites_conf_reverse.vcf
    tabix -f $faDir/random_${n}_sites_conf_reverse.vcf.gz
fi

if [ ! -f $simulDir/${sample}.sorted.vcf.gz ]; then
	bgzip -f $simulDir/${sample}.sorted.vcf
fi
tabix -f $simulDir/${sample}.sorted.vcf.gz
if [ ! -f $origDir/${sample}.sorted.vcf.gz ]; then
	bgzip -f $origDir/${sample}.sorted.vcf
fi
tabix -f $origDir/${sample}.sorted.vcf.gz

### Subtract the original variants called from hg19 reference
rtg vcfeval -b $origDir/$sample.sorted.vcf.gz -c $simulDir/$sample.sorted.vcf.gz -t $faDir/random_${n}_sites_conf.sdf -o $subDir --squash-ploidy 

### evaluation of the subtracted vcf and the inserted random mutations
rtg vcfeval -b $faDir/random_${n}_sites_conf_reverse.vcf.gz -c $subDir/fp.vcf.gz -t $faDir/random_${n}_sites_conf.sdf -o $evalDir --squash-ploidy --sample ALT,ALT --output-mode=annotate
