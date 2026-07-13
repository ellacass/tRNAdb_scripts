#!/bin/bash


DOMAIN_FLAG="-A"

# Loop over every .fna file in the current directory
for fna_file in <path>/*.fna; do
    [ -e "$fna_file" ] || continue
    
    # Create a base name (e.g., sample.fna -> sample)
    base=$(basename "$fna_file" .fna)
    
    echo "Processing: $fna_file ..."
    
    # Run tRNAscan-SE with structured outputs
    tRNAscan-SE $DOMAIN_FLAG \
        --thread 8 \
        -o "TACK/${base}_trnascan.stats.txt" \
        -f "TACK/${base}_structures.txt" \
        -m "TACK/${base}_run_summary.stats" \
        "$fna_file"

done

echo "All files processed successfully!"
