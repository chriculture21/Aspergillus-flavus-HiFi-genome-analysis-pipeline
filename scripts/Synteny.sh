#A script for genome alignment between the reference genome and our genome
#First, use minimap2 for whole genome alignment

mkdir synteny
minimap2 -x asm5 --eqx -t 8 synteny/reference.fna synteny/BAF47.nuclear.fa > synteny/BAF47_vs_ref.sam

#asm5 is needed to closely related 
#Check with a dotplot (for example in D-GENIES online tool) if you have inverted chromosomes. Sort to match the reference and
#download the sorted query fasta file containing the sorted chromosomes
#For synteny analysis with SyRi, the chromosome names need to be the same for the target and the reference genomes

cd synteny
sed -i -e 's/^>ptg000002l.*/>chr1/' \
       -e 's/^>ptg000003l.*/>chr2/' \
       -e 's/^>ptg000004l.*/>chr3/' \
       -e 's/^>ptg000005l.*/>chr4/' \
       -e 's/^>ptg000001l.*/>chr5/' \
       -e 's/^>ptg000008l.*/>chr6/' \
       -e 's/^>ptg000006l.*/>chr7/' \
       -e 's/^>ptg000007l.*/>chr8/' \
       BAF47.nuclear.fa
grep ">" BAF47.nuclear.fa

sed -i -e 's/^>NC_092406\.1.*/>chr1/' \
       -e 's/^>NC_092409\.1.*/>chr2/' \
       -e 's/^>NC_092407\.1.*/>chr3/' \
       -e 's/^>NC_092405\.1.*/>chr4/' \
       -e 's/^>NC_092408\.1.*/>chr5/' \
       -e 's/^>NC_092410\.1.*/>chr6/' \
       -e 's/^>NC_092404\.1.*/>chr7/' \
       -e 's/^>NC_092403\.1.*/>chr8/' \
       reference.fna
grep ">" reference.fna

#running the initial minimap2, we observed that 7 out of 8 chromosomes were reversed, so they need to be in the same orientation for SyRi

conda activate fg-core

seqkit grep -p chr3 BAF47.nuclear.fa > tmp_forward.fa
seqkit grep -v -p chr3 BAF47.nuclear.fa | seqkit seq -r -p -t dna > tmp_reversed.fa

seqkit fx2tab -n -l tmp_forward.fa
seqkit fx2tab -n -l tmp_reversed.fa

cat tmp_forward.fa tmp_reversed.fa | seqkit sort -N > BAF47.chr.fa
rm tmp_forward.fa tmp_reversed.fa
seqkit fx2tab -n -l BAF47.chr.fa

minimap2 -ax asm5 --eqx -t 8 reference.fna BAF47.chr.fa > BAF47_vs_ref.chr.sam

conda activate syri_env

syri -c BAF47_vs_ref.chr.sam -r reference.fna -q BAF47.chr.fa -F S --prefix BAF47_vs_ref. --nc 4
#S for sam files, P for paf files, B for bam files

printf "reference.fna\tNRRL 3357\tlw:1.5\nBAF47.chr.fa\tBAF47\tlw:1.5\n" > genomes.txt
cat genomes.txt

plotsr --sr BAF47_vs_ref.syri.out --genomes genomes.txt -o BAF47_vs_NRRL3357_plotsr.png -H 8 -W 7
