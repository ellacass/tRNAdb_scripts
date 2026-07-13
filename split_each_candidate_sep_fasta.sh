# 1. Create a dedicated directory to hold the individual FASTA files
mkdir -p individual_fastas

for file in *_structures.txt; do
    echo "Splitting sequences from: $file"
    
    /usr/bin/awk '
    # Match the header line containing "Length:"
    /Length:/ {
        full_id = $1;
        coords = $2;
        gsub(/[()]/, "", coords); # Remove parentheses
        
        split(full_id, id_parts, ".");   taxon_id = id_parts[1];
        split(full_id, v_parts, "_");    version_id = v_parts[1];
    }
    
    # Match the line starting with "Type:" to grab AA and Anticodon
    /^Type:/ {
        amino_acid = $2;
        anticodon = $4;
    }
    
    # Match the sequence line, construct the header, and write to a unique file
    /^Seq:/ {
        sequence = $2;
        
        # Build the exact header string (without quotes)
        header = sprintf("%s_%s_%s_%s_%s", taxon_id, version_id, coords, amino_acid, anticodon);
        
        # Define the unique path and filename
        filename = "individual_fastas/" header ".fasta";
        
        # Write out the file cleanly
        printf ">%s\n%s\n", header, sequence > filename;
        
        # Close the file immediately to avoid hitting macOS open-file limits
        close(filename);
    }
    ' "$file"
done

echo "----------------------------------------"
echo "Done! Check the 'individual_fastas' folder."
echo "Total files generated: $(ls -1 individual_fastas | wc -l)"
