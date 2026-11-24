#Before starting with the assembly, we need to do a quality control check on the raw reads to ensure that everything is okay.
#This includes generating plots for the read length distribution and read quality distribution. Because we have HiFi reads, we use Nanoplot
#Create a new env and activate it

conda create -n fg-qual -y nanoplot
conda activate fg-qual

cd ~/Aspergillus-flavus-HiFi-genome-analysis-pipeline/results
mkdir -p QC
cd QC

#run nanoplot on the raw HiFi reads
NanoPlot \
	--ubam ~/fungal-genomics-course/Aspergillus_project/raw_reads/BAF47_reads.bam \
	-t 2 \
	-o NanoPlot_BAF47 \
	-p BAF47_ \
	--N50 \
	--title "A. flavus BAF47 HiFi reads"

#observe the results
cat BAF47_NanoStats.txt
