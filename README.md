# Genome Assembly and Annotation of a Toxigenic *Aspergillus flavus* Strain (BAF47) Isolated from Corn

This repository documents the genome assembly, quality control, repeat annotation and gene prediction of *Aspergillus flavus* strain **BAF47** from PacBio HiFi reads. It contains two versions of the analysis:

1. **Command-line pipeline (main)**: step-by-step bash scripts run locally on Ubuntu (WSL2) with conda environments. This is the version described in detail below.
2. **Galaxy workflow**: an end-to-end Galaxy workflow (`.ga` file) covering the same steps plus functional annotation. See [Galaxy workflow](#galaxy-workflow).

Only scripts and small result tables are stored here. Raw reads, assemblies and other large files are excluded (see `.gitignore`).

---

## Biological context

*Aspergillus flavus* is a filamentous fungus of major agricultural and public health importance, responsible for aflatoxin contamination of crops worldwide. A high-quality, chromosome-level genome of a toxigenic strain from corn provides the basis for studying its secondary metabolite gene clusters, including the aflatoxin cluster, and for comparisons with non-toxigenic strains.

---

## Key results

| | BAF47 |
|---|---|
| **Sequencing** | PacBio Revio HiFi: 135,474 reads, 1.90 Gb, ~50× coverage |
| **Read length N50** | 19.0 kb |
| **Read quality** | Median Q35.5; 96.8% of reads ≥ Q20 |
| **Nuclear assembly** | 8 contigs, 37,755,576 bp, no gaps |
| **Telomere-to-telomere** | 7 of 8 chromosomes (telomeric repeat `TTAGGGTCAACA` at both ends) |
| **Mitochondrial genome** | Identified and separated from the nuclear assembly |
| **BUSCO (genome)** | 98.3% complete (`eurotiomycetes_odb12`) |
| **Repeats** | 1.66% of the genome masked; transposable elements 0.82%, mostly LTR/Gypsy |
| **Gene prediction** | funannotate |
| **Genome visualization** | karyoploteR | 

---

## Pipeline overview

```
PacBio HiFi reads (.bam)
      │
      ├──► [1] Read QC ............................ NanoPlot, seqkit stats
      │
      ▼
[2] De novo assembly .............................. hifiasm
      │
      ▼
[3] Assembly QC and cleaning
      ├── contig length, depth and GC .............. awk, seqkit
      ├── mitochondrial / repeat contigs ........... minimap2 vs. reference
      ├── telomere detection ....................... seqkit subseq + locate
      └── completeness ............................. BUSCO (genome mode)
      │
      ▼
   Nuclear assembly (8 chromosomes)
      │
      ▼
[4] Repeat annotation
      ├── de novo repeat library ................... RepeatModeler (Galaxy)
      └── soft-masking ............................. RepeatMasker -xsmall
      │
      ▼
[5] Gene prediction ............................... funannotate predict
      ├── protein evidence: A. flavus NRRL 3357 + Swiss-Prot (DIAMOND + Exonerate)
      ├── ab initio: Augustus, SNAP, GlimmerHMM (trained on BUSCO genes)
      └── consensus: EVidenceModeler
      │
      ▼
[6] Annotation QC ....................... BUSCO (protein mode), gene statistics
      │
      ▼
[7] Functional annotation ............... funannotate annotate, InterProScan,
                                                    eggNOG-mapper, antiSMASH
```

---

## Step details

### 1. Read quality control
NanoPlot was run on the unaligned HiFi BAM to summarise read length and quality distributions.

```bash
NanoPlot --ubam BAF47_reads.bam -t 2 -o NanoPlot_BAF47 -p BAF47_ --N50 \
  --title "A. flavus BAF47 HiFi reads"
```

### 2. Genome assembly
Reads were assembled with the tool hifiasm. The primary contig graph (`*.bp.p_ctg.gfa`) was converted to FASTA, and per-contig length and read depth were taken from the GFA segment (`S`) lines.

### 3. Assembly QC and cleaning
- **Contig table:** length, read depth and GC content per contig, combined into one table with `awk`.
- **Mitochondrial genome:** identified by high depth, low GC and circularity, and saved separately.
- **Extra contigs:** small contigs were aligned to the main assembly with `minimap2 -x asm5`. Those fully contained in it (repeat copies) were removed, leaving 8 nuclear contigs.
- **Telomeres:** the first and last 2 kb of each contig were searched for the *Aspergillus* telomeric repeat `TTAGGGTCAACA`. 7 of 8 contigs carry telomeres at both ends.
- **BUSCO:** genome mode with the `eurotiomycetes_odb12` lineage.

### 4. Repeat annotation
A de novo repeat library was built with RepeatModeler (run on Galaxy because of its compute demands). The nuclear assembly was then soft-masked locally:

```bash
RepeatMasker -lib BAF47-families.fasta -xsmall -gff -pa 4 -dir masking BAF47.nuclear.fa
```

`-xsmall` writes repeats in lowercase (soft-masking), so gene predictors can still read them but avoid starting genes inside transposons.

### 5. Gene prediction
Gene prediction used protein evidence and ab initio predictors trained on BUSCO genes.

```bash
funannotate setup -d $FUNANNOTATE_DB -i uniprot busco repeats -b eurotiomycetes

funannotate predict \
  -i BAF47.nuclear.fa.masked \
  -o funannotate_BAF47 \
  -s "Aspergillus flavus" --strain BAF47 --name BAF47_ \
  --busco_db eurotiomycetes \
  --busco_seed_species aspergillus_oryzae \
  --protein_evidence GCF_009017415.1_protein.faa $FUNANNOTATE_DB/uniprot_sprot.fasta \
  --cpus 8
```

- **Protein evidence:** the reference proteome of *A. flavus* NRRL 3357 (RefSeq GCF_009017415.1, 13,707 proteins) and UniProt Swiss-Prot.
- **BUSCO seed species:** *A. oryzae*, the closest relative of *A. flavus* among the pre-trained Augustus models.
- **GeneMark** was not used (separate licence).

---

## Repository structure

```
.
├── README.md
├── LICENSE
├── *.ga                      # Galaxy workflow
├── scripts/                  # bash scripts for each step
│   ├── Quality_control.sh
│   ├── Annotation.sh
│   └── ...
└── results/                  # small result tables (TSV/TXT)
    ├── QC/                   # NanoPlot read statistics
    ├── Busco/                # BUSCO summaries
    ├── Repeats/              # RepeatMasker summary (.tbl, .out)
    └── Annotation/           # gene prediction summaries
```

---

## Software

| Tool | Version | Purpose |
|------|---------|---------|
| NanoPlot | 1.48.0 | Read QC |
| seqkit | 2.14.0 | Sequence statistics, subsequences, motif search |
| hifiasm | 0.25.0-r726 | De novo HiFi assembly |
| minimap2 | 2.26-r1175 | Contig-to-assembly alignment |
| BUSCO | 6.1.0 | Assembly completeness |
| RepeatModeler | 2.0.5 (Galaxy) | De novo repeat library |
| RepeatMasker | 4.2.4 | Soft-masking |
| funannotate | 1.8.17 | Gene prediction pipeline |
| Augustus | 3.5.0 | Ab initio gene prediction |
| SNAP | 2006-07-28 | Ab initio gene prediction |
| GlimmerHMM | 3.0.4 | Ab initio gene prediction |
| DIAMOND | 2.2.8 | Fast protein-to-genome search |
| Exonerate | 2.4.0 | Spliced protein alignment |
| tRNAscan-SE | 2.0.13 | tRNA prediction |
| karyoploteR | 1.32.0 | Genome visualization |

All tools were installed with conda (channels: conda-forge, bioconda) on Ubuntu 24.04 (WSL2).

---

## Galaxy workflow

The `.ga` file in this repository is a Galaxy workflow that runs the full analysis end-to-end, from the raw `.bam` file to a functionally annotated genome with biosynthetic gene cluster predictions: BAM to FASTQ → hifiasm → GFA to FASTA → BUSCO → RepeatModeler → RepeatMasker → funannotate predict → InterProScan / eggNOG-mapper / antiSMASH → funannotate annotate → BUSCO (protein mode).

**To import it:**
1. Log in to a Galaxy server (e.g. [usegalaxy.eu](https://usegalaxy.eu)).
2. Go to **Workflows → Import**.
3. Upload the `.ga` file, or paste the raw GitHub URL of the file (open the file on GitHub, click **Raw**, copy the URL).
4. Click **Import workflow**.

**To run it:** upload your HiFi BAM file and an *A. flavus* mRNA/EST FASTA (transcript evidence) to your history, open the workflow, assign the two inputs, and click **Run Workflow**.

---

## Citations

- **NanoPlot**: De Coster & Rademakers (2023) *Bioinformatics* 39(5):btad311
- **SeqKit**: Shen et al. (2016) *PLoS ONE* 11(10):e0163962
- **hifiasm**: Cheng et al. (2021) *Nature Methods* 18:170–175
- **minimap2**: Li (2018) *Bioinformatics* 34(18):3094–3100
- **BUSCO**: Manni et al. (2021) *Molecular Biology and Evolution* 38(10):4647–4654
- **RepeatModeler2**: Flynn et al. (2020) *PNAS* 117(17):9451–9457
- **funannotate**: Palmer & Stajich (2020) Zenodo, https://doi.org/10.5281/zenodo.4054262
- **AUGUSTUS**: Stanke et al. (2006) *Nucleic Acids Research* 34:W435–W439
- **EVidenceModeler**: Haas et al. (2008) *Genome Biology* 9:R7
- **DIAMOND**: Buchfink et al. (2021) *Nature Methods* 18:366–368
- **Exonerate**: Slater & Birney (2005) *BMC Bioinformatics* 6:31

---

## Contact

For questions, please open an issue in this repository.

## License

Released under the [MIT License](LICENSE).
