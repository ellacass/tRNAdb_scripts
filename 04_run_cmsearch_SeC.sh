for fasta_file in *SeC*.fasta; do
    base=$(basename "$fasta_file" .fasta)
    echo "Processing: $base"
    cmsearch \
        -o "infernal_results/${base}_cmsearch.out" \
        --tblout "infernal_results/${base}_cmsearch.tblout" \
        --notextw \
        TRNAinf-arch-SeC.cm "$fasta_file"
done

echo "Done!"
