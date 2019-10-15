#!/lustre1/zeminz_pkuhpc/01.bin/R/R-3.5.2/mybuild/bin/R
options(scipen=999)

library(bedr)

args <- commandArgs(TRUE)
inFile <- paste(args[1],".bed",sep="")
outFile <- paste(args[1],".vcf",sep="")
fastaFile = args[2]
a <- read.table(inFile, header = FALSE, stringsAsFactors = FALSE);
colnames(a) <- c("a.CHROM", "a.START", "a.END", "n", "length", "strand");
a <- bedr.sort.region(a);
myvcf = bed2vcf(a, filename = outFile, fasta = fastaFile)

