#!/bin/bash

# ============================================================
# Script: ultra_fast_96core_heatmap.sh
# ============================================================

INPUT_FILE=$1
OUTPUT_PREFIX=$2
CORES=$(nproc)-4

if [ -z "$OUTPUT_PREFIX" ]; then
    echo "Usage: $0 H_PLOT.txt output_prefix"
    exit 1
fi

WINDOW_SIZE=100
echo "Processing with $CORES cores (Native Forking)..."

# 1. Extract data
IFS=$'\t' read -r ID SEQ HSTR < <(tail -n +2 "$INPUT_FILE")
DATA_BIN="matrix_${ID}.bin"

# 2. Multi-threaded Binary Matrix Generator (Native Perl Fork)
echo "$HSTR" | perl -e '
    use strict;
    my ($win, $cores) = @ARGV;
    my $input = <STDIN>;
    my @raw = split(/\s+/, $input);
    my @binned;

    # Pre-binning
    for (my $i=0; $i < @raw; $i += $win) {
        my ($s, $c) = (0, 0);
        for (my $j=$i; $j < $i+$win && $j < @raw; $j++) { $s += $raw[$j]; $c++; }
        push @binned, $s/$c;
    }

    my $N = scalar @binned;
    my @pids;

    for (my $cpu = 0; $cpu < $cores; $cpu++) {
        my $pid = fork();
        if ($pid == 0) { # Child process
            open my $FH, ">", "chunk_$cpu.tmp" or die $!;
            binmode $FH;
            my $start_j = int($N * $cpu / $cores);
            my $end_j   = int($N * ($cpu + 1) / $cores) - 1;

            for my $j ($start_j .. $end_j) {
                my $row = "";
                for my $i (0 .. $N - 1) {
                    $row .= pack("f", ($binned[$i] + $binned[$j]) / 2);
                }
                print $FH $row;
            }
            close $FH;
            exit(0);
        } else {
            push @pids, $pid;
        }
    }
    # Wait for all 96 children
    foreach my $pid (@pids) { waitpid($pid, 0); }
' "$WINDOW_SIZE" "$CORES"

# 3. Concatenate and clean up
cat chunk_*.tmp > "$DATA_BIN"
rm chunk_*.tmp

# Calculate N for gnuplot
N=$(echo "$HSTR" | perl -e 'my $w=$ARGV[0]; my @r=split(/\s+/, <STDIN>); print int(scalar(@r)/$w)' "$WINDOW_SIZE")

# 4. Gnuplot Binary Render
gnuplot << EOF
    set terminal pngcairo size 1500,1350 enhanced font 'Verdana,12'
    set output '${OUTPUT_PREFIX}_${ID}.png'

    # Diverging Blue-White-Red Palette
    # -4.5 (Hydrophilic): Royal Blue
    #  0.0 (Neutral):     White
    # +4.5 (Hydrophobic): Firebrick Red
    set palette defined (-4.5 "#00008B", -2.25 "#6495ED", 0 "#FFFFFF", 2.25 "#FF6347", 4.5 "#B22222")

    set title "Genome Hydropathy: ${ID}\n{/*0.8 Parallel Binary Render | Window: ${WINDOW_SIZE} | Cores: ${CORES}}"
    set view map
    set size square

    # Ensure the color range is symmetric around zero
    set cbrange [-4.5:4.5]
    set cblabel "Avg Hydropathy (Blue: Hydrophilic | Red: Hydrophobic)"

    set autoscale fix
    splot '${DATA_BIN}' binary array=${N}x${N} format='%f' with pm3d notitle
EOF

rm "$DATA_BIN"
echo "Success: ${OUTPUT_PREFIX}_${ID}.png"