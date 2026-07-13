# tRNAdb_scripts

> Processing pipeline for archaeal tRNA annotation

All scripts for each processing step are provided in this repository. This pipeline
generates tRNA annotations for **977 complete archaeal genomes** across four major
phylogenetic groups, of which **962 taxon IDs are not currently represented** in the
existing tRNAdb.

---

## Dataset summary

| Group | Total Genomes | Unique Taxonomic RANK | tRNAs | Undet/NNN | Pseudo |
|---|---:|---:|---:|---:|
| Asgard | 103 | 22 | 4,343 | 53 | 94 |
| DPANN | 177 | 29 | 6,624 | 50 | 227 |
| TACK | 460 | 122 | 20,241 | 119 | 334 |
| Euryarchaeota | 237 | 55 | 9,530 | 27 | 66 |
| **Total** | **977** | **40,738** | **249** | **627** |

> Asgard pseudo counts pending completion of pipeline run.

---

##  Genome selection

Genomes were sourced from **BV-BRC** and filtered using **CheckM2** with the
following criteria:

-  Completeness ≥ 85%
-  Contamination ≤ 5%
-  No duplicate assemblies (verified by MD5 checksum on sequence content,
  excluding FASTA headers)

---

## Why BV-BRC tRNA annotations were not used

BV-BRC tRNA annotations were found to be inconsistent with archaeal-mode
tRNAscan-SE 2.0 output. Discrepancies are most consistent with an older version
of tRNAscan-SE run in a non-archaeal mode — likely the general mode (`-G`) or
equivalent, as BV-BRC is a prokaryote-wide database not specific to archaea.
Evidence includes:

- **~20%** of tRNA loci found by `-A` are absent from BV-BRC entirely,
  of which **83% are intron-containing tRNAs**
- A further **~10%** are present but untyped (labelled `Pseudo` or `Undet`)
- `tRNA-Ile2` is systematically miscalled as `tRNA-Met` (agmatidine blind spot)
- Some BV-BRC entries use `Sec` capitalisation consistent with tRNAscan-SE 1.x
  rather than `SeC` used in 2.0
- Coordinate truncations at intron boundaries consistent with older annotation tools

**tRNAscan-SE 2.0.12 in archaeal mode (`-A`) is used exclusively throughout
this pipeline.**

---

##  Dependencies

| Tool | Version |
|---|---|
| tRNAscan-SE | 2.0.12 |
| Infernal / cmsearch | 1.1.5 (Sep 2023) |

Covariance models are bundled with tRNAscan-SE and located at:
`$CONDA_PREFIX/lib/tRNAscan-SE/models/`

| Model | Purpose |
|---|---|
| `TRNAinf-arch.cm` | General archaeal tRNA covariance model |
| `TRNAinf-arch-SeC.cm` | Selenocysteine-specific archaeal model |

---

##  Filename convention

All individual tRNA FASTA files and cmsearch outputs follow this naming scheme:

```
<taxonid>_<genome_accession>_<contig>_<start>-<end>_<isotype>_<anticodon>[_Pseudo].fasta
```

| Field | Description | Example |
|---|---|---|
| `taxonid` | NCBI taxon ID | `2910166` |
| `genome_accession` | BV-BRC genome ID (`taxonid.version`) | `2910166.71` |
| `contig` | Contig/scaffold accession | `DATDYS010000013` |
| `start-end` | Coordinates as reported by tRNAscan-SE | `88808-88703` |
| `isotype` | tRNA type | `Thr` |
| `anticodon` | Anticodon triplet | `TGT` |
| `_Pseudo` | Optional — pseudogene prediction | `_Pseudo` |

> **Note on coordinates:** orientation is preserved from tRNAscan-SE output.
> Minus-strand entries have end < start (e.g. `88808-88703`).
> Plus-strand entries have start < end (e.g. `1920-2011`).

**Examples:**
```
2910166_2910166.71_DATDYS010000013_88808-88703_Thr_TGT.fasta
2910166_2910166.71_DATDYS010000013_88808-88703_Thr_TGT_Pseudo.fasta
1916003_1916003.3_DALG01000012_1920-2011_Thr_TGT_Pseudo_cmsearch.out
```

---

## Pipeline

### Step 1 — Run tRNAscan-SE (`01_run_trnascan.sh`)

Retrieve all initial tRNA candidates from complete archaeal genomes using
archaeal mode (`-A`). Two covariance models are invoked automatically:
`TRNAinf-arch.cm` for all standard tRNAs and `TRNAinf-arch-SeC.cm` for
selenocysteine tRNAs.

Two output files are produced per genome:

```
<genome_accession>_trnascan.stats.txt    # tabular results; pseudo flag in note column
<genome_accession>_structures.txt        # full secondary structure output
```

Pseudogene candidates are retained and flagged with `pseudo` in the note column.

---

### Step 2 — Split candidates into individual FASTAs (`02_split_individual_fastas.sh`)

Each tRNA candidate is extracted into its own FASTA file for downstream
cmsearch validation. Sequences are taken from `*_structures.txt`. The genome
accession and taxon ID are parsed from the structures filename; the contig is
extracted from the tRNAscan entry header.

> Pseudogene candidates lacking a `Seq:` line in the structures output
> (typically the most degenerate entries) are not represented in
> `individual_fastas/` and are absent from downstream steps.

---

### Step 3 — Run cmsearch with archaeal model (`03_run_cmsearch_arch.sh`)

Each individual FASTA is validated by `cmsearch` against `TRNAinf-arch.cm`,
providing an independent Infernal-based score. Two output files are produced
per candidate, written to `infernal_results/`:

```
<filename_stem>_cmsearch.out      # full cmsearch output
<filename_stem>_cmsearch.tblout   # tabular hit table
```

---

### Step 4 — Rerun cmsearch for SeC with SeC-specific model (`04_run_cmsearch_SeC.sh`)

`tRNA-SeC` has an atypical secondary structure that scores poorly against the
general archaeal CM. All SeC candidates are rerun against `TRNAinf-arch-SeC.cm`,
overwriting the Step 3 outputs. SeC candidates are identified by `_SeC_` in
the filename.

> **SeC tRNAs are present only in Asgard and Euryarchaeota** in this dataset
> and appear absent from DPANN and TACK. Step 4 can be skipped for those groups.

---

### Step 5 — Add `_Pseudo` tag (`05_add_pseudo_labels.sh`)

tRNAscan-SE flags low-scoring candidates as `pseudo` in the stats output —
candidates that score above the noise floor but below the confident tRNA
threshold (~50–55 bits in archaeal mode). All pseudo-flagged loci with a
corresponding FASTA are renamed to append `_Pseudo` to:

- The FASTA filename and internal `>header` line
- Both cmsearch output files (`.out` and `.tblout`)

Pseudo tRNAs are retained for further review.

---

## Directory structure

```
tRNAdb_scripts/
├── 01_run_trnascan.sh
├── 02_split_individual_fastas.sh
├── 03_run_cmsearch_arch.sh
├── 04_run_cmsearch_SeC.sh
├── 05_add_pseudo_labels.sh
└── README.md

Per-group working directories (not in repo):
<Group>/                                      e.g. DPANN/, TACK/, Asgard/, Eury/
├── <genome_accession>_trnascan.stats.txt
├── <genome_accession>_structures.txt
└── individual_fastas/
    ├── <tRNA_id>.fasta
    ├── <tRNA_id>_Pseudo.fasta
    └── infernal_results/
        ├── <tRNA_id>_cmsearch.out
        └── <tRNA_id>_cmsearch.tblout
```
