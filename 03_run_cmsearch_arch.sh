
mkdir -p <output_dir>

# Checkz if your CM file is indexed
cmpress TRNAinf-arch.cm

echo "Starting batch cmsearch on individual candidates..."
echo "------------------------------------------------"

for fasta_file in *.fasta; do
    base=$(basename "$fasta_file" .fasta)
    
    echo "Processing candidate: $base"

    cmsearch \
                               -o "<output_dir>/${base}_cmsearch.out" \
                               --tblout "<output_dir>/${base}_cmsearch.tblout" \
								--notextw \
                                TRNAinf-arch.cm "$fasta_file"
done

echo "------------------------------------------------"
echo "All done! Outputs are saved in the 'infernal_results' directory."
