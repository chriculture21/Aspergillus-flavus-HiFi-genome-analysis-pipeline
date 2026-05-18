# Genome Assembly and Annotation of a non-toxigenic Strain of *Aspergillus flavus*

## Overview

This Galaxy workflow performs **de novo genome assembly, structural prediction, functional annotation, and secondary metabolite detection** for a non-toxigenic strain of *Aspergillus flavus* (strain AAF4) using PacBio HiFi long-read sequencing data. The workflow is fully automated and runs end-to-end from raw `.bam` input to a functionally annotated genome with biosynthetic gene cluster (BGC) predictions.

---

## Biological Context

*Aspergillus flavus* is a filamentous fungus of major agricultural and public health significance, responsible for aflatoxin contamination in crops worldwide. This workflow was designed to characterize a non-toxigenic strain (AAF4) at the genomic level, enabling downstream analyses of secondary metabolite gene clusters.

---

## Workflow Summary

```
HiFi reads (.bam)
      │
      ▼
[1] PacBio bam2fastx        → Convert BAM to FASTQ
      │
      ▼
[2] Hifiasm                 → De novo genome assembly (GFA format)
      │
      ▼
[3] GFA to FASTA            → Convert primary contig graph to FASTA
      │
      ├──────────────────────────────────────┐
      ▼                                      ▼
[4] BUSCO (genome mode)             [5] RepeatModeler
    Assembly quality assessment         Build repeat library
                                               │
                                               ▼
                                        [6] RepeatMasker
                                            Mask repeats in assembly
                                               │
      mRNA/ESTs (FASTA) ────────────────────► │
                                               ▼
                                        [7] Funannotate predict
                                            Structural gene prediction
                                               │
                          ┌────────────────────┼──────────────────┐
                          ▼                    ▼                   ▼
                   [8] InterProScan    [9] eggNOG Mapper    [10] antiSMASH
                   Protein domain          Orthology &         Secondary
                   annotation              GO annotation       metabolite BGCs
                          │                    │
                          └────────┬───────────┘
                                   ▼
                          [11] Funannotate functional
                               Final functional annotation
                                   │
                                   ▼
                          [12] BUSCO (protein mode)
                               Annotation completeness
```

---

## Tools and Versions

| Step | Tool | Version | Purpose |
|------|------|---------|---------|
| 1 | PacBio bam2fastx | 3.5.0+galaxy0 | Convert PacBio BAM to FASTQ |
| 2 | Hifiasm | 0.25.0+galaxy1 | De novo HiFi genome assembly |
| 3 | GFA to FASTA | 0.1.2 | Convert assembly graph to FASTA |
| 4 | BUSCO | 5.8.0+galaxy2 | Genome assembly completeness |
| 5 | RepeatModeler | 2.0.5+galaxy0 | De novo repeat library construction |
| 6 | RepeatMasker | 4.1.5+galaxy0 | Repeat masking of genome |
| 7 | Funannotate predict | 1.8.17+galaxy0 | Structural gene prediction |
| 8 | InterProScan | 5.59-91.0+galaxy3 | Protein domain & GO annotation |
| 9 | eggNOG Mapper | 2.1.13+galaxy0 | Orthology & functional annotation |
| 10 | antiSMASH | 6.1.1+galaxy1 | Biosynthetic gene cluster detection |
| 11 | Funannotate functional | 1.8.17+galaxy5 | Final functional annotation integration |
| 12 | BUSCO | 5.8.0+galaxy2 | Protein annotation completeness |

---

## Input Files

| Input | Format | Description |
|-------|--------|-------------|
| `AAF4_mix.hifi_reads.bam` | BAM | PacBio HiFi reads for strain AAF4 |
| `mRNA_ESTs_Aflavus for prediction.fasta` | FASTA | *A. flavus* mRNA/EST sequences used as transcript evidence for gene prediction |

---

## Output Files

| Output | Format | Source Tool | Description |
|--------|--------|-------------|-------------|
| Assembly FASTA | FASTA | GFA to FASTA | Primary contig assembly |
| BUSCO summary (genome) | TXT | BUSCO | Assembly completeness report |
| Masked genome | FASTA | RepeatMasker | Repeat-masked assembly |
| Repeat catalog | TXT | RepeatMasker | Identified repeat elements |
| Predicted annotation | GenBank | Funannotate predict | Structural gene models |
| Predicted proteins | FASTA | Funannotate predict | Predicted protein sequences |
| InterProScan results | TSV / XML | InterProScan | Domain and GO annotations |
| eggNOG annotations | Tabular | eggNOG Mapper | Ortholog and COG assignments |
| antiSMASH results | GenBank / HTML | antiSMASH | Biosynthetic gene cluster predictions |
| Final annotation | GenBank / GFF3 / FASTA | Funannotate functional | Complete annotated genome |
| BUSCO summary (proteins) | TXT | BUSCO | Annotation completeness report |

---

## Key Tool Parameters

### Hifiasm
- Mode: Standard HiFi assembly
- Filter bits: 37

### BUSCO
- Lineage: `eurotiomycetes_odb10` (appropriate for *Aspergillus*)
- Genome mode: Augustus-based gene prediction
- Protein mode: Direct protein assessment

### Funannotate predict
- Organism: *Aspergillus flavus*, strain AAF4
- Protein evidence: UniProt
- BUSCO seed species: *Aspergillus nidulans*
- Min protein length: 50 aa
- Max intron length: 3,000 bp
- Gene prefix: `AfAAF4_`

### InterProScan
- Databases: Pfam, TIGRFAM, PANTHER, SMART, CDD, Gene3D, SUPERFAMILY, PRINTS, Hamap, PIRSF, MobiDBLite, Coils, FunFam, SFLD, PIRSR, PrositeProfiles, PrositePatterns, AntiFam
- GO terms: enabled
- Pathway mapping: enabled

### antiSMASH
- Taxon: Fungi
- Gene finding: GlimmerHMM
- ClusterBlast: enabled (general, known clusters, subclusters)
- MIBiG comparison: enabled
- RRE detection: enabled
- smCOG trees: enabled
- Minimum cluster length: 1,000 bp

---

## How to Import and Run This Workflow

### Option A — Import from Galaxy interface
1. Log in to your Galaxy instance (e.g., [usegalaxy.eu](https://usegalaxy.eu))
2. Go to **Workflow** → **Import**
3. Upload the `.ga` file or paste the raw GitHub URL of the file
4. Click **Import workflow**

### Option B — Import via URL (from GitHub)
1. Navigate to the `.ga` file on GitHub
2. Click **Raw** and copy the URL
3. In Galaxy: **Workflow** → **Import** → paste the raw URL

### Running the workflow
1. Upload your input files to Galaxy history
2. Open the imported workflow and click **Run**
3. Assign:
   - `AAF4_mix.hifi_reads.bam` → your PacBio HiFi BAM file
   - `mRNA_ESTs_Aflavus for prediction.fasta` → your transcript evidence FASTA
4. Click **Run Workflow**

---

## Citation

If you use this workflow, please cite the following tools:

- **Hifiasm**: Cheng et al. (2021) *Nature Methods* 18:170–175
- **BUSCO**: Manni et al. (2021) *Molecular Biology and Evolution* 38(10):4647–4654
- **RepeatModeler/RepeatMasker**: Flynn et al. (2020) *PNAS* 117(17):9451–9457
- **Funannotate**: Palmer & Stajich (2020) *Zenodo* https://doi.org/10.5281/zenodo.4054262
- **InterProScan**: Jones et al. (2014) *Bioinformatics* 30(9):1236–1240
- **eggNOG Mapper**: Cantalapiedra et al. (2021) *Molecular Biology and Evolution* 38(12):5825–5829
- **antiSMASH**: Blin et al. (2021) *Nucleic Acids Research* 49(W1):W29–W35

---

## Contact

For questions about this workflow, please open an issue in this repository.

---

## License

This workflow is released under the [MIT License](LICENSE).
