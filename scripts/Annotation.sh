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

#download the protein evidence of the reference genome
mkdir reference
cd reference
conda activate fg-core #this env contains the datasets
datasets download genome taxon "Aspergillus flavus" --reference --include protein --filename A_flavus_ref.zip

conda activate funannotate
#the databases need to be downloaded first, if they are not do so:
conda env config vars set FUNANNOTATE_DB=$HOME/funannotate_db
conda deactivate
conda activate funannotate
funannotate setup -d $FUNANNOTATE_DB -i uniprot busco repeats -b eurotiomycetes
funannotate database

#Now, we need to predict  annotate our masked genome using the reference and the downloaded protein files. 
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
	
