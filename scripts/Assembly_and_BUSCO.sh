conda activate fg-core 

#start by checking the .bam file with samtools, to see if you have CSS reads or any other type

samtools view -H BAF47_reads.bam | grep "^@RG"
#^@RG is the pattern that you want to check in the file, inside the file you will see 
# the READTYPE=CSS so you are good to go by converting the .bam file to .fastq

samtools fastq -@ 8 BAF47_reads.bam | gzip -c | BAF47_reads.fastq.gz
# this way you use 8 threads, you choose the option fastq to convert to fastq (which is needed for the quality scores etc)
# and then you name the file with the extension fastq.gz (if you use gzip -c)

#chck the statistics
seqkit stats -a BAF47_reads.fastq.gz
#check the Q20 and Q30, for HiFi reads you need more than 94%

#It's time for the assembly! Since we have CSS reads, the hifiasm is the tool to go
#first activate the environment with:
conda activate fg-asm

#then run the hifiasm tool:
hifiasm -o A_flavus_BAF47 -t 8 -l0 -f0 ~/fungal-genomics-course/Aspergillus_project/raw_reads/BAF47_reads.fastq.gz

#once the assembly is finished, check the .gfa file. Now we need to convert the .gfa file to .fa or .fasta
#taking only the contig name and the sequence. This will be done with awk searching for the S pattern in the .gfa file.
awk '/^S/ {print ">"$2; print $3}' A_flavus_BAF47.bp.p_ctg.gfa > A_flavus_BAF47_p_ctg.fa
#this makes a new file that print >, the second column which is the contig name, and the third column which is the sequence

#check the stats again
seqkit stats -a A_flavus_BAF47_p_ctg.fa > ~/fungal-genomics-course/Aspergillus_project/results/BAF47_assembly_stats.tsv

#then do a sanity check on your assembly. Isolate the contigs, the length, and the depth for each contig 
awk -F'\t' 'BEGIN {OFS = "\t"} $1 == "S" {print $2, substr($4, 6), substr($5, 6)}' *.bp.p_ctg.noseq.gfa | sort -k2,2nr > ~/fungal-genomics-course/Aspergillus_project/results/BAF47.contigs.tsv

#then isolate the GC content for each contig. In the previous file we see that after the contig name, we have l or c. c stands for circular
#and it is probably the mitochondrial DNA. This needs to be removed. Moreover, you see 8 large contigs with about 50 depth, while you see 6
#more that have a depth around 0. These mught be repeats, so probably the 8 large contigs are the 8 chromosomes.
#isolate the gc content with seqkit fx2tab
seqkit fx2tab -n -i -g A_flavus_BAF47_p_ctg.fa | cut -f1,2 > ~/fungal-genomics-course/Aspergillus_project/results/BAF47_gc.tsv

#then join the two tables
awk -F'\t' 'BEGIN {OFD = "\t"}
NR == NFR {gc[$1] = $2; next} 
{print $1, $2, $3, gc[$1]}' BAF47.gc.tsv BAF47.contigs.tsv > BAF_congc.tsv
cat BAF47_contigs_gc.tsv

#inspect the file. We can see the length, the depth and the GC content of each contig. Then we can isolate the large contigs (>1.000.000 bp)
#and separate them from the mitochondrial (circular) DNA or repeats
fasta=~/fungal-genomics-course/Aspergillus_project/assembly/A_flavus_BAF47_p_ctg.fa
table=~/fungal-genomics-course/Aspergillus_project/results/BAF47_contigs_gc.tsv
ls -lh "$fasta" "$table"

awk '$2 >= 1000000 {print $1}' "$table" > nuclear.txt
awk '$2 < 1000000 && $1 != "ptg000011c" {print $1}' "$table" > others.txt

seqkit grep -f nuclear.txt "$fasta" > nuclear.fa
seqkit grep -p ptg000011c "$fasta" > mito.fa
seqkit grep -f others.txt "$fasta" > others.fa
cat nuclear.fa mito.fa > reference.fa

#align the odd contigs to the 8 large contigs to see if we have contamination, or it is just repeats of the core genome.
minimap2 -x asm5 -t 8 reference.fa others.fa > others_vs_ref.paf 2> /dev/null 

#start with the busco analysis. This gives the completeness of the assembly and its a quality check.

