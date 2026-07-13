## tRNAdb_scripts
All processing steps of tRNAs used for tRNAdb

## run tRNAscan-SE (v. 2.0.12)
Retrieve all initial tRNA candidates from complete archaeal genomes 

## split each candidate seq identified by tRNAscan
Prepare to run infernal/cmsearch on each individual fasta of tRNA identified

## run cmsearch using tRNAinf_Arch
Run on each individual fasta using model specified 

## for SeC predictions rerun infernal using tRNAinf_SeC model 
SeC requires different intron splicing models
Only necessary for asgard and euryarchaeota, SeC seems absent in DPANN and TACK phyla

## add "Pseudo" tag to those tRNAs predicted as pseudo
Keep all pseudo predicted tRNAs for now and add pseudo tag, filenames look like:

2910166_2910166.71_DATDYS010000013_88808-88703_Thr_TGT_Pseudo.fasta
<taxonid>_<accession_BV_BRC>_<contig>_<start-end>_<prediction>_<anticodon>_<Pseudo>

this tag is also added to the cmsearch output files:
1916003_1916003.3_DALG01000012_1920-2011_Thr_TGT_Pseudo_cmsearch.out
