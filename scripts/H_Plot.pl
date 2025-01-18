#!\usr\bin\perl  

$/ = '\777';

# entire input to be read in one slurp
$seqs = <>;

# read input, assigning to single string
while ( $seqs =~ m/^(>[^>]+)/mg ) {

    # match indiv. sequences by '>'s = Fasta Format
    push( @seqs, $1 );

    # and store in array
}
for (@seqs) {    # only allow characters A-Z,a-z,0-9,'_','-', and '.' in names;
    /^> *([\w\-\.]+)/ && ( $seq_name = $1 );
    if ($seq_name) {
        my $seqI = $_;
        $seqI =~ s/^>*.+\n//;

        # remove FASTA header
        $seqI =~ s/\n//g;

        # remove endlines
        my $value = '';
        my $codon = '';
        for ( my $i = 0 ; $i < ( length($seqI) ) ; $i += 1 ) {
            $codon = substr( $seqI, $i, 1 );
            $value .= seq2value($codon);
        }

        # write out-file
        open( MYFILE, '>>H_PLOT.txt' );
        printf MYFILE ( '%1$6s %2$6s %3$6s', $seq_name, $seqI, $value );
        print MYFILE "\n";
        close(MYFILE);

        # on-screen output
        print "  \n\n$seq_name $value\n\n";
    }
    else { warn "couldn't recognise the sequence name in \n$_"; }
}
exit;

#sub hydropathy-scale - kyte-doolittle
sub seq2value {
    my ($codon) = @_;
    $codon = uc $codon;
    my (%scale) = (
        'A' => '1.80 ',
        'R' => '-4.50 ',
        'N' => '-3.50 ',
        'C' => '2.50 ',
        'D' => '-3.50 ',
        'E' => '-3.50 ',
        'F' => '2.80 ',
        'G' => '-0.40 ',
        'H' => '-3.29 ',
        'I' => '4.50 ',
        'K' => '-3.90 ',
        'L' => '3.80 ',
        'M' => '1.90 ',
        'P' => '-1.60 ',
        'Q' => '-3.50 ',
        'S' => '-0.80 ',
        'T' => '-0.70 ',
        'V' => '4.20 ',
        'W' => '-0.90 ',
        'Y' => '-130 ',
    );
    if ( exists $scale{$codon} ) {
        return $scale{$codon};
    }

    #else {print STDERR "Bad Amino Acid !!\n";exit;}
}
exit;
