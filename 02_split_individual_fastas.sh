mkdir -p individual_fastas
for file in *_structures.txt; do
    echo "Splitting sequences from: $file"
    
    # Extract genome ID and taxon ID from filename
    genome_id="${file/_structures.txt/}"
    taxon_id="${genome_id%%.*}"

    /usr/bin/awk -v genome_id="$genome_id" -v taxon_id="$taxon_id" '
    /Length:/ {
        full_id = $1;
        coords = $2;
        gsub(/[()]/, "", coords);

        # Contig: everything in full_id before .trnaX
        contig = full_id;
        sub(/\.trna[0-9]+$/, "", contig);
    }

    /^Type:/ {
        amino_acid = $2;
        anticodon = $4;
    }

    /^Seq:/ {
        sequence = $2;

        header = sprintf("%s_%s_%s_%s_%s_%s", taxon_id, genome_id, contig, coords, amino_acid, anticodon);

        filename = "individual_fastas/" header ".fasta";
        printf ">%s\n%s\n", header, sequence > filename;
        close(filename);
    }
    ' "$file"
done
echo "----------------------------------------"
echo "Done! Check the 'individual_fastas' folder."
echo "Total files generated: $(ls -1 individual_fastas | wc -l)"
