#!/bin/bash
set -o nounset
#set -o errexit
 
#########################################
#written by Fenglin
#AIM: to call variants using different tools
#########################################
project=$1
patient=$2
sample=$3 
pipe=$4

if [ "$pipe" = "ctat" ]; then
	python2.7 $path_to_CTAT/ctat_mutations --left $fq1 --right $fq2 --out_dir $outDir --reference $faFile --skip_cravat --genome_lib_dir $genome_lib_dir
	cp $outDir/variants_initial_filtering_clean_snp_RNAedit.vcf.gz $outDir/${sample}.sorted.vcf.gz
fi

if [ "$pipe" = "gsnap-ctat" ]; then
	python2.7 $path_to_CTAT/ctat_mutations --left $fq1 --right $fq2 --out_dir $outDir --reference $faFile --skip_cravat --bam $inBam_gsnap --genome_lib_dir $genome_lib_dir
	cp $outDir/variants_initial_filtering_clean_snp_RNAedit.vcf.gz $outDir/${sample}.sorted.vcf.gz
fi

if [ "$pipe" = "gatk" ]; then
        #java -jar picard.jar MarkDuplicates I=$inBam O=$dedupped_bam CREATE_INDEX=true M=$output_metrics
	#java -jar $path_to_gatk/gatk SplitNCigarReads -R $faFile -I $dedupped_bam -O $split_bam --read-validation-stringency LENIENT
	#java -jar $path_to_gatk/gatk BaseRecalibrator -R $faFile -I $split_bam -O $recalibrated_bam_tmp1 --known-sites $vcf_file
	#java -jar $path_to_gatk/gatk PrintReads -I $split_bam -O $recalibrated_bam_tmp2
	#java -jar $path_to_gatk/gatk ApplyBQSR -I $recalibrated_bam_tmp2 -O $recalibrated_bam -bqsr $recalibrated_bam_tmp1	
	inBam=$recalibrated_bam
	$path_to_gatk/gatk HaplotypeCaller -R $faFile -I $inBam --recover-dangling-heads true --dont-use-soft-clipped-bases -stand-call-conf 0 -O $outDir/$sample.pre.vcf #to adjust parameters
	$path_to_gatk/gatk VariantFiltration -R $faFile -V $outDir/$sample.pre.vcf -window 35 -cluster 3 --filter-name FS -filter "FS > 30.0" --filter-name QD -filter "QD < 2.0" -O $outDir/$sample.filtered.vcf
	cat $outDir/$sample.filtered.vcf |grep -e "#\|PASS"  >$outDir/${sample}.vcf
fi

if [ "$pipe" = "strelka" ]; then
        $path_to_strelka2/bin/configureStrelkaGermlineWorkflow.py --bam $inBam --referenceFasta $faFile --runDir $outDir --rna
        $outDir/runWorkflow.py -m local -j 8
	less $outDir/results/variants/variants.vcf.gz |grep "#\|PASS" > $outDir/$sample.vcf
fi

if [ "$pipe" = "mutect" ]; then
	inBam=$recalibrated_bam
	$path_to_gatk/gatk Mutect2 -R $faFile -I $inBam -O $outDir/$sample.vcf -tumor $sm --tumor-lod-to-emit 5 --initial-tumor-lod 5 #to adjust paramters
fi

if [ "$pipe" = "varscan" ]; then
	samtools mpileup -f $faFile $inBam |java -jar $path_to_varscan/VarScan.v2.4.3.jar mpileup2snp --min-coverage 1 --min-reads2 1 --output-vcf 1 --strand-filter 0 --p-value 0.95 >$outDir/$sample.vcf #to adjust parameters
fi

if [ "$pipe" = "freebayes" ]; then
	inBam=$dedupped_bam
	$path_to_freebayes/bin/freebayes -C 0 -F 0 --fasta-reference $faFile $inBam > $outDir/$sample.vcf #to adjust paramters
	/lustre1/zeminz_pkuhpc/01.bin/vcflib/bin/vcffilter -f "QUAL > 20" $outDir/$sample.vcf |bgzip -c > $outDir/${sample}.sorted.vcf.gz
fi

if [ "$pipe" = "samtools" ]; then
	$path_to_bcftools/bcftools mpileup -Q 30 -A -x -Ou -f $faFile $inBam |$path_to_bcftools/bcftools call -mv > $outDir/${sample}.vcf
fi
