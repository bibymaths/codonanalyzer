#!/bin/bash
INPUT_FILE=$1
OUTPUT_PREFIX=$2

if [ -z "$OUTPUT_PREFIX" ]; then
    echo "Usage: $0 H_PLOT.txt output_prefix"
    exit 1
fi

WINDOW_SIZE=100
IFS=$'\t' read -r ID SEQ HSTR < <(tail -n +2 "$INPUT_FILE")
echo "Processing genome: $ID"

# Write binned values to a temp file (O(N) — just the 1D array)
TMPBINS=$(mktemp /tmp/bins_XXXXXX.txt)
trap "rm -f $TMPBINS" EXIT

echo "$HSTR" | perl -e '
    use strict;
    my $win = $ARGV[0];
    my @raw = split(/\s+/, <STDIN>);
    for (my $i = 0; $i < @raw; $i += $win) {
        my ($s, $c) = (0, 0);
        for (my $j=$i; $j < $i+$win && $j < @raw; $j++) { $s+=$raw[$j]; $c++; }
        printf("%.4f\n", $s/$c);
    }
' "$WINDOW_SIZE" > "$TMPBINS"

N=$(wc -l < "$TMPBINS")

# Downsample if too large
MAX_BINS=800
if [ "$N" -gt "$MAX_BINS" ]; then
    STEP=$(( (N + MAX_BINS - 1) / MAX_BINS ))
    echo "Downsampling: 1 of every $STEP bins"
    awk "NR % $STEP == 0" "$TMPBINS" > "${TMPBINS}.ds"
    mv "${TMPBINS}.ds" "$TMPBINS"
    N=$(wc -l < "$TMPBINS")
fi
echo "Bins: $N x $N"

# Stream matrix row-by-row through a named pipe — never buffered in RAM
FIFO=$(mktemp -u /tmp/gnuplot_XXXXXX.fifo)
mkfifo "$FIFO"
trap "rm -f $TMPBINS $FIFO" EXIT

# Perl streams one row at a time into the fifo in background
perl -e '
    use strict;
    open my $FH, "<", $ARGV[0] or die $!;
    my @b = map { chomp; $_ } <$FH>;
    close $FH;
    my $N = scalar @b;
    open my $OUT, ">", $ARGV[1] or die $!;
    for my $i (0..$N-1) {
        for my $j (0..$N-1) {
            print $OUT (($b[$i]+$b[$j])/2);
            print $OUT ($j < $N-1 ? " " : "\n");
        }
    }
    close $OUT;
' "$TMPBINS" "$FIFO" &
PERL_PID=$!

gnuplot << EOF
    set terminal pngcairo size 1500,1350 enhanced font 'Verdana,12'
    set output '${OUTPUT_PREFIX}_${ID}.png'
    set palette defined (-4.5 "#00008B", -2.25 "#6495ED", 0 "#FFFFFF", 2.25 "#FF6347", 4.5 "#B22222")
    set title "Genome Hydropathy: ${ID}\n{/*0.8 Window: ${WINDOW_SIZE}}"
    set view map
    set size square
    set cbrange [-4.5:4.5]
    set cblabel "Avg Hydropathy (Blue: Hydrophilic | Red: Hydrophobic)"
    set autoscale fix
    plot '${FIFO}' matrix with image notitle
EOF

wait $PERL_PID
echo "Success: ${OUTPUT_PREFIX}_${ID}.png"