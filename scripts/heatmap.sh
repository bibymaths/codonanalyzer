#!/bin/bash

# ============================================================
# Script: genome_heatmap_gnuplot.sh
# Usage: ./genome_heatmap_gnuplot.sh H_PLOT.txt output_prefix
# ============================================================

INPUT_FILE=$1
OUTPUT_PREFIX=$2

if [ -z "$OUTPUT_PREFIX" ]; then
    echo "Usage: $0 H_PLOT.txt output_prefix"
    exit 1
fi

# ADJUST WINDOW SIZE HERE:
# 500-1000 is best for whole genomes
WINDOW_SIZE=100

echo "Using Window Size: $WINDOW_SIZE"

# Process records using a robust while loop
# We skip the header and read the tab-separated values
tail -n +2 "$INPUT_FILE" | while IFS=$'\t' read -r ID SEQ HSTR; do
    echo "Processing record: $ID"

    DATA_TMP="tmp_matrix_${ID}.dat"

    # Pre-processor: Now using STDIN to avoid "Argument list too long"
    echo "$HSTR" | perl -e '
        my $win = $ARGV[0];
        # Read from STDIN
        my $input = <STDIN>;
        my @raw = split(/\s+/, $input);
        my @binned;

        # Binning logic
        for (my $i=0; $i < @raw; $i += $win) {
            my ($s, $c) = (0, 0);
            for (my $j=$i; $j < $i+$win && $j < @raw; $j++) { $s += $raw[$j]; $c++; }
            push @binned, $s/$c;
        }

        my $N = scalar @binned;
        # Print matrix for Gnuplot
        for my $j (0..$N-1) {
            for my $i (0..$N-1) {
                printf "%.3f ", ($binned[$i] + $binned[$j])/2;
            }
            print "\n";
        }
    ' "$WINDOW_SIZE" > "$DATA_TMP"

    # Check if the matrix was actually created
    if [ ! -s "$DATA_TMP" ]; then
        echo "Error: Matrix generation failed for $ID"
        continue
    fi

# Generate Gnuplot Script with Viridis Theme
    gnuplot << EOF
        set terminal pngcairo size 1200,1000 enhanced font 'Verdana,10'
        set output '${OUTPUT_PREFIX}_${ID}.png'

        # High-precision Viridis Palette definition
        set palette defined ( \
          0 "#440154", 1 "#482878", 2 "#3E4989", 3 "#31688E", \
          4 "#26828E", 5 "#1F9E89", 6 "#35B779", 7 "#6DCD59", \
          8 "#B4DE2C", 9 "#FDE725" )

        set title "Genome Hydropathy Dot-Plot: ${ID}\n{/*0.8 Window Size: ${WINDOW_SIZE} residues (Viridis Theme)}"
        set xlabel "Position X (bins of ${WINDOW_SIZE})"
        set ylabel "Position Y (bins of ${WINDOW_SIZE})"

        set tic scale 0
        set view map
        set size square

        # Hydropathy values range from -4.5 to 4.5
        set cbrange [-4.5:4.5]
        set cblabel "Avg Hydropathy (Dark: Hydrophilic | Yellow: Hydrophobic)"

        splot '${DATA_TMP}' matrix with pm3d notitle
EOF

    rm "$DATA_TMP"
    echo "Successfully saved: ${OUTPUT_PREFIX}_${ID}.png"
done

echo "Process Complete."