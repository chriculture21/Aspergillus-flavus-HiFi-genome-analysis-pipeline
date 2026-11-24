#This is a file that includes the script for RepeatModeler, RepeatMasker (to identify TEs) and also functional annotation
#First go to the desired folder, and then create a folder named "Repeats"

conda activate fg-repeat

cd /../..
mkdir Repeats

#First create the database (index the genome) with the prefix BAF47
BuildDatabase -name BAF47 ~/fungal-genomics-course/Aspergillus_project/results/BAF47.nuclear.fa 
#BAF47.nuclear.fa is the input file to build the database

#run RepeatModeler
RepeatModeler -database BAF47 -threads 8 2>&1 | tee repeatmodeler.log
#we add the 2>&1 | tee repeatmodeler.log to see both the output and the errors on screen

#Using the repeat families found with RepeatModeler as input, soft-mask the genome with RepeatMasker
RepeatMasker -lib BAF47-families.fa -xsmall -gff -pa 4 -dir masking BAF47.nuclear.fa
#xsmall is for soft-masking the genome (use lowecase letters instead if Ns for repeats), save also the results in a gff file
#and save the masked genome in a folder named "masking"

#observe the table with the results
cat BAF47.nuclear.fa.tbl

mkdir reference
cd reference
conda activate fg-core #this env contains the datasets
datasets download genome taxon "Aspergillus flavus" --reference --include protein --filename A_flavus_ref.zip

#Now, we need to predict  annotate our masked genome. 
funannotate predict \
	-i results/Repeats/masking/BAF47.nuclear.fa.masked \
	-o results/Annotation/funannotate_BAF47 \
	-s "Aspergillus flavus" \
	--strain BAF47 \
	--name BAF47_ \
	--busco_db eurotiomycetes \
	--busco_seed_species aspergillus_oryzae \
	--protein_evidence reference/A_flavus_ref/ncbi_dataset/data/GCF_009017415.1/protein.faa $FUNANNOTATE_DB/uniprot_sprot.fasta \
	--cpus 8
	
