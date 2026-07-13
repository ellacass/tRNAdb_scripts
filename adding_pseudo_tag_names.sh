#!/usr/bin/env bash
# Usage: bash add_pseudo_labels.sh [--dry-run]
#
# Key construction:
#   stats file: 1805247.3_trnascan.stats.txt  -> genome_id = 1805247.3
#   contig from file content: MNVE01000001
#   key: 1805247.3_MNVE01000001_8224-8128
#
#   FASTA filename: 1805247_1805247.3_MNVE01000001_8224-8128_Tyr_GTA
#   key: field2_field3_field4 = 1805247.3_MNVE01000001_8224-8128  ✓

DRY_RUN=false
[[ "$1" == "--dry-run" ]] && DRY_RUN=true && echo "*** DRY RUN — no files will be renamed ***"

STATS_DIR=""
FASTA_DIR=""
CMSEARCH_DIR=""

renamed_fasta=0
renamed_cmsearch=0

# ── Build pseudo locus lookup ──────────────────────────────────────────────
echo "Building pseudo locus lookup from stats files..."

declare -A PSEUDO

for stats_file in "$STATS_DIR"/*_trnascan.stats.txt; do
    # Extract genome ID from filename: 1805247.3_trnascan.stats.txt -> 1805247.3
    genome_id=$(basename "$stats_file" _trnascan.stats.txt)

    while IFS= read -r line; do
        [[ "$line" =~ ^(Sequence|Name|---) ]] && continue
        [[ -z "$line" ]] && continue
        [[ "$line" != *pseudo* ]] && continue

        contig=$(echo "$line" | awk '{print $1}')
        begin=$(echo "$line"  | awk '{print $3}')
        end=$(echo "$line"    | awk '{print $4}')

        # Prepend genome_id to contig to match FASTA filename key format
        key1="${genome_id}_${contig}_${begin}-${end}"
        key2="${genome_id}_${contig}_${end}-${begin}"
        PSEUDO["$key1"]=1
        PSEUDO["$key2"]=1

    done < "$stats_file"
done

echo "Found ${#PSEUDO[@]} pseudo loci (both orientations)"

# ── Debug output ───────────────────────────────────────────────────────────
echo ""
echo "Sample pseudo keys from stats:"
for key in "${!PSEUDO[@]}"; do echo "  $key"; done | head -5

echo ""
echo "Sample FASTA filename and extracted key:"
for f in "$FASTA_DIR"/*.fasta; do
    [ -f "$f" ] || { echo "  No fasta files found in $FASTA_DIR"; break; }
    base=$(basename "$f" .fasta)
    genome_id=$(echo "$base" | awk -F_ '{print $2}')
    contig=$(echo "$base"    | awk -F_ '{print $3}')
    coords=$(echo "$base"    | awk -F_ '{print $4}')
    key="${genome_id}_${contig}_${coords}"
    echo "  file:      $base"
    echo "  genome_id: $genome_id"
    echo "  contig:    $contig"
    echo "  coords:    $coords"
    echo "  key:       $key"
    break
done
echo ""

# ── Rename FASTAs ──────────────────────────────────────────────────────────
echo "=== FASTA files ==="
for f in "$FASTA_DIR"/*.fasta; do
    [ -f "$f" ] || continue
    base=$(basename "$f" .fasta)
    [[ "$base" == *_Pseudo ]] && continue

    genome_id=$(echo "$base" | awk -F_ '{print $2}')
    contig=$(echo "$base"    | awk -F_ '{print $3}')
    coords=$(echo "$base"    | awk -F_ '{print $4}')
    key="${genome_id}_${contig}_${coords}"

    if [[ -n "${PSEUDO[$key]}" ]]; then
        newname="${base}_Pseudo"
        echo "RENAME: ${base}.fasta  ->  ${newname}.fasta"
        if ! $DRY_RUN; then
            mv "$f" "$FASTA_DIR/${newname}.fasta"
            sed -i "s/^>${base}$/>${newname}/" "$FASTA_DIR/${newname}.fasta"
        fi
        ((renamed_fasta++))
    fi
done

# ── Rename cmsearch outputs ────────────────────────────────────────────────
echo ""
echo "=== Cmsearch files ==="
for f in "$CMSEARCH_DIR"/*_cmsearch.out "$CMSEARCH_DIR"/*_cmsearch.tblout; do
    [ -f "$f" ] || continue
    base=$(basename "$f")
    [[ "$base" == *_Pseudo* ]] && continue

    trna_id="${base/_cmsearch.out/}"
    trna_id="${trna_id/_cmsearch.tblout/}"
    suffix="${base/$trna_id/}"

    genome_id=$(echo "$trna_id" | awk -F_ '{print $2}')
    contig=$(echo "$trna_id"    | awk -F_ '{print $3}')
    coords=$(echo "$trna_id"    | awk -F_ '{print $4}')
    key="${genome_id}_${contig}_${coords}"

    if [[ -n "${PSEUDO[$key]}" ]]; then
        newname="${trna_id}_Pseudo${suffix}"
        echo "RENAME: $base  ->  $newname"
        if ! $DRY_RUN; then
            mv "$f" "$CMSEARCH_DIR/${newname}"
        fi
        ((renamed_cmsearch++))
    fi
done

echo ""
echo "========================================"
echo "FASTAs renamed:    $renamed_fasta"
echo "Cmsearch renamed:  $renamed_cmsearch"
echo "========================================"
$DRY_RUN && echo "*** DRY RUN complete — rerun without --dry-run to apply ***"
