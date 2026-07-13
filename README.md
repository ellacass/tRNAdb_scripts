# tRNAdb_scripts
All processing steps of tRNAs used for tRNAdb

# run tRNAscan-SE (v. 2.0.12)
Retrieve all initial tRNA candidates from complete archaeal genomes 

# split each candidate seq identified by tRNAscan
Prepare to run infernal/cmsearch on each individual fasta of tRNA identified

# run cmsearch using tRNAinf_Arch
Run on each individual fasta using model specified 

# for SeC predictions rerun infernal using tRNAinf_SeC model 
SeC requires different intron splicing models
Only necessary for asgard and euryarchaeota, SeC seems absent in DPANN and TACK phyla
