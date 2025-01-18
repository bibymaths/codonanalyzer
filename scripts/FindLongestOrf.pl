#!/usr/bin/perl -w




my $fastafile;
my $orftable;
my $sequences;
my $opened;
my $line;
my $start_pos;
my $stop_pos;
my $seqEntry;
my $seq;
my $def;
my $pos;
my $spos;
my $strand  = 1;    #search on positive strand reading frames only
my %genemap = ();
my $ntseq;
my $m_size;
my $m_start;
my $m_stop;
my $m_ntseq;
my $m_aaseq;
my $m_def;


my $nucleotideoption;
my $wholent = 0;

my %translationTable = (
    GCA => "A",
    GCG => "A",
    GCT => "A",
    GCC => "A",
    GCN => "A",
    GCR => "A",
    GCW => "A",
    GCY => "A",
    GCM => "A",
    GCK => "A",
    GCS => "A",
    GCH => "A",
    GCB => "A",
    GCV => "A",
    GCD => "A",
    RAC => "B",
    RAT => "B",
    RAY => "B",
    TGC => "C",
    TGT => "C",
    TGY => "C",
    GAT => "D",
    GAC => "D",
    GAY => "D",
    GAA => "E",
    GAG => "E",
    GAR => "E",
    TTT => "F",
    TTC => "F",
    TTY => "F",
    GGA => "G",
    GGG => "G",
    GGC => "G",
    GGT => "G",
    GGN => "G",
    GGR => "G",
    GGW => "G",
    GGY => "G",
    GGM => "G",
    GGK => "G",
    GGS => "G",
    GGH => "G",
    GGB => "G",
    GGV => "G",
    GGD => "G",
    CAT => "H",
    CAC => "H",
    CAY => "H",
    ATA => "I",
    ATT => "I",
    ATC => "I",
    ATM => "I",
    ATW => "I",
    ATY => "I",
    ATH => "I",
    AAA => "K",
    AAG => "K",
    AAR => "K",
    CTA => "L",
    CTG => "L",
    CTT => "L",
    CTC => "L",
    CTN => "L",
    CTR => "L",
    CTW => "L",
    CTY => "L",
    CTM => "L",
    CTK => "L",
    CTS => "L",
    CTH => "L",
    CTB => "L",
    CTV => "L",
    CTD => "L",
    TTA => "L",
    TTG => "L",
    TTR => "L",
    YTA => "L",
    YTG => "L",
    ATG => "M",
    AAT => "N",
    AAC => "N",
    AAY => "N",
    CCA => "P",
    CCT => "P",
    CCG => "P",
    CCC => "P",
    CCN => "P",
    CCR => "P",
    CCW => "P",
    CCY => "P",
    CCM => "P",
    CCK => "P",
    CCS => "P",
    CCH => "P",
    CCB => "P",
    CCV => "P",
    CCD => "P",
    CAA => "Q",
    CAG => "Q",
    CAR => "Q",
    CGA => "R",
    CGG => "R",
    CGC => "R",
    CGT => "R",
    CGN => "R",
    CGR => "R",
    CGW => "R",
    CGY => "R",
    CRM => "R",
    CGK => "R",
    CGS => "R",
    CGH => "R",
    CGB => "R",
    CGV => "R",
    CGD => "R",
    MGA => "R",
    MGG => "R",
    AGA => "R",
    AGG => "R",
    AGR => "R",
    AGC => "S",
    AGT => "S",
    AGY => "S",
    TCA => "S",
    TCG => "S",
    TCC => "S",
    TCT => "S",
    TCN => "S",
    TCR => "S",
    TCW => "S",
    TCY => "S",
    TCM => "S",
    TCK => "S",
    TCS => "S",
    TCH => "S",
    TCB => "S",
    TCV => "S",
    TCD => "S",
    ACA => "T",
    ACG => "T",
    ACC => "T",
    ACT => "T",
    ACN => "T",
    ACR => "T",
    ACW => "T",
    ACY => "T",
    ACM => "T",
    ACK => "T",
    ACS => "T",
    ACH => "T",
    ACB => "T",
    ACV => "T",
    ACD => "T",
    GTA => "V",
    GTG => "V",
    GTC => "V",
    GTT => "V",
    GTN => "V",
    GTR => "V",
    GTW => "V",
    GTY => "V",
    GTM => "V",
    GTK => "V",
    GTS => "V",
    GTH => "V",
    GTB => "V",
    GTV => "V",
    GTD => "V",
    TGG => "W",
    TAT => "Y",
    TAC => "Y",
    TAY => "Y",
    SAA => "Z",
    SAG => "Z",
    SAR => "Z",
    TAG => "*",
    TAA => "*",
    TGA => "*",
    TAR => "*",
    TRA => "*"
);

# get the program arguments from the command line
if ( $#ARGV < 2 ) {
    die(    "Not enough arguments\n"
          . " [need three arguments: fasta-file output-file (+/-)]\n" );
}
$fastafile        = $ARGV[0];
$orftable         = $ARGV[1];
$nucleotideoption = $ARGV[3];
if ( $nucleotideoption eq "whole" ) {
    $wholent = 1;
}
if ( $ARGV[2] eq "+" ) {
    $strand = 1;    #search on positive strand reading frames only
}
else {
    $strand = -1;    #search on negative strand reading frames only
}

#open/create the output file
$opened = open( OUT, ">" . $orftable );
if ( !$opened ) {
    print "Error opening $orftable!";
    exit 1;
}

#open/create the output file
$opened = open( OUTFASTA, ">" . $orftable . ".fasta" );
if ( !$opened ) {
    print "Error opening $orftable.fasta!";
    exit 1;
}

# read the feature file (execl exported html file)
$opened = open( SEQDATA, $fastafile );
if ( !$opened ) {
    close(OUT);
    print "Error opening $fastafile!";
    exit 1;
}
$sequences = "";
while ( $line = <SEQDATA> ) {
    $sequences = $sequences . $line;
}
close(SEQDATA);
print( "Read " . length($sequences) . " char\n" );
$start_pos = 0;
while ( $start_pos < length($sequences) ) {
    $start_pos = index( $sequences, ">", $start_pos );
    if ( $start_pos < 0 ) {
        $start_pos = length($sequences);
    }
    else {
        $stop_pos = index( $sequences, ">", $start_pos + 1 );
        if ( $stop_pos < 0 ) {
            $stop_pos = length($sequences);
        }
        $seqEntry = substr( $sequences, $start_pos, $stop_pos - $start_pos );
        chomp($seqEntry);
        $seq = "";
        $def = "";
        $pos = index( $seqEntry, "\n" );
        if ( $pos < 0 ) {
            $pos = index( $seqEntry, "\r" );
        }
        if ( $pos < 0 ) {
            print("ERROR: Invalid input format!");
        }
        else {
            $def = substr( $seqEntry, 1, $pos );
            chomp($def);
            $def =~ s/\s+$//;
            $def =~ s/^\s+//;
            $line = substr( $seqEntry, $pos + 1 );
            chomp($line);
            $pos = 0;
            while ( $pos < length($line) ) {
                $spos = $pos;
                $pos = index( $line, "\n", $pos );
                if ( $pos < 0 ) {
                    $pos = index( $line, "\r", $pos );
                }
                if ( $pos < $spos ) {
                    $seq = $seq . substr( $line, $spos );
                    $pos = length($line);
                }
                else {
                    $seq = $seq . substr( $line, $spos, $pos - $spos );
                }
                chomp($seq);
                $seq =~ s/\s+$//;
                $seq =~ s/^\s+//;
                $pos++;
            }
            $seq =~ tr/atgcnumrykvhdbxsw/ATGCNUMRYKVHDBXSW/;
        }
        if ( length($def) > 0 ) {
            if ( length($seq) > 0 ) {
                $genemap{$def} = $seq;
            }
        }
        $start_pos = $stop_pos;
    }
}
$seq = "";
my @arrayOfORFs = ();
while ( my ( $key, $seqval ) = each(%genemap) ) {
    print "$key\n";
    $seq = $seqval;
    if ( $strand < 0 ) {
        $seq =~ tr/ACGT/TGCA/;              #make complement
        $seq =~ tr/UMRYKVHDB/AKYRMBDHV/;    #make complement
        for ( my $frame = 0 ; $frame < 3 ; $frame = $frame + 1 ) {
            for (
                my $cpos = ( length($seq) - $frame ) ;
                $cpos > 2 ;
                $cpos = $cpos - 3
              )
            {
                my $codon =
                    substr( $seq, $cpos - 1, 1 )
                  . substr( $seq, $cpos - 2, 1 )
                  . substr( $seq, $cpos - 3, 1 );
                if ( $codon eq "ATG" ) {
                    my $isStopCodon = 0;
                    for ( my $epos = $cpos - 3 ; $epos > 2 ; $epos = $epos - 3 )
                    {
                        my $scodon =
                            substr( $seq, $epos - 1, 1 )
                          . substr( $seq, $epos - 2, 1 )
                          . substr( $seq, $epos - 3, 1 );
                        if ( $scodon eq "TGA" ) {
                            $isStopCodon = 1;
                        }
                        if ( $scodon eq "TAA" ) {
                            $isStopCodon = 1;
                        }
                        if ( $scodon eq "TAG" ) {
                            $isStopCodon = 1;
                        }
                        if ( $scodon eq "TAR" ) {
                            $isStopCodon = 1;
                        }
                        if ( $scodon eq "TRA" ) {
                            $isStopCodon = 1;
                        }
                        if ( $isStopCodon > 0 ) {
                            push( @arrayOfORFs,
                                    "-"
                                  . ( $frame + 1 ) . " "
                                  . ( $epos - 2 ) . ".."
                                  . $cpos );
                            $epos = 0;
                        }
                    }
                    if ( $isStopCodon < 1 ) {
                        push( @arrayOfORFs,
                            "-" . ( $frame + 1 ) . " " . "1.." . $cpos );
                    }
                }
            }
        }
    }
    else {
        for ( my $frame = 0 ; $frame < 3 ; $frame = $frame + 1 ) {
            for (
                my $cpos = $frame ;
                $cpos < ( length($seq) - 3 ) ;
                $cpos = $cpos + 3
              )
            {
                my $codon =
                    substr( $seq, $cpos, 1 )
                  . substr( $seq, $cpos + 1, 1 )
                  . substr( $seq, $cpos + 2, 1 );
                if ( $codon eq "ATG" ) {
                    my $isStopCodon = 0;
                    for (
                        my $epos = $cpos ;
                        $epos < ( length($seq) - 3 ) ;
                        $epos = $epos + 3
                      )
                    {
                        my $scodon =
                            substr( $seq, $epos, 1 )
                          . substr( $seq, $epos + 1, 1 )
                          . substr( $seq, $epos + 2, 1 );
                        if ( $scodon eq "TGA" ) {
                            $isStopCodon = 1;
                        }
                        if ( $scodon eq "TAA" ) {
                            $isStopCodon = 1;
                        }
                        if ( $scodon eq "TAG" ) {
                            $isStopCodon = 1;
                        }
                        if ( $scodon eq "TAR" ) {
                            $isStopCodon = 1;
                        }
                        if ( $scodon eq "TRA" ) {
                            $isStopCodon = 1;
                        }
                        if ( $isStopCodon > 0 ) {
                            push( @arrayOfORFs,
                                    "+"
                                  . ( $frame + 1 ) . " "
                                  . $cpos . ".."
                                  . ( $epos + 2 ) );
                            $epos = length($seq);
                        }
                    }
                    if ( $isStopCodon < 1 ) {
                        push( @arrayOfORFs,
                                "+"
                              . ( $frame + 1 ) . " "
                              . $cpos . ".."
                              . length($seq) );
                    }
                }
            }
        }
    }
    $m_def   = "";
    $m_start = 0;
    $m_stop  = 0;
    $m_size  = 0;
    $m_ntseq = "";
    foreach (@arrayOfORFs) {
        if ( $strand < 0 ) {
            $_ =~ m/([\-]\d)\s(\d+)\.\.(\d+)/;
            print "Reading frame $1 " . $2 . " to " . $3;
            print ", Length: "
              . ( ( $3 - $2 ) + 1 ) . " ["
              . length($seq) . "]\n";
            open( F1, '>>ReadingFrames_neg.txt' );
            print F1 "Reading frame $1 " . $2 . " to " . $3;
            print F1 ", Length: "
              . ( ( $3 - $2 ) + 1 ) . " ["
              . length($seq) . "]\n";
            $ntseq = "";
            for ( my $i = ( $3 - 1 ) ; $i > ( $2 - 2 ) ; $i = $i - 1 ) {
                $ntseq = $ntseq . substr( $seq, $i, 1 );
                close(F1);
            }
            if ( ( ( $3 - $2 ) + 1 ) > $m_size ) {
                $m_start = $2;
                $m_stop  = $3;
                $m_size  = ( $3 - $2 ) + 1;
                $m_ntseq = $ntseq;
                $m_def   = $key;
            }
        }
        else {
            $_ =~ m/([\+]\d)\s(\d+)\.\.(\d+)/;
            print "Reading frame $1 " . $2 . " to " . $3;
            print ", Length: "
              . ( ( $3 - $2 ) + 1 ) . " ["
              . length($seq) . "]\n";
            open( F2, '>>ReadingFrames_pos.txt' );
            print F2 "Reading frame $1 " . $2 . " to " . $3;
            print F2 ", Length: "
              . ( ( $3 - $2 ) + 1 ) . " ["
              . length($seq) . "]\n";
            $ntseq = substr( $seq, $2, ( $3 - $2 + 1 ) );
            if ( ( ( $3 - $2 ) + 1 ) > $m_size ) {
                $m_start = $2;
                $m_stop  = $3;
                $m_size  = ( $3 - $2 ) + 1;
                $m_ntseq = $ntseq;
                $m_def   = $key;
            }
        }
    }
    @arrayOfORFs = ();
    $m_aaseq     = "";
    for ( my $k = 0 ; $k < ( length($m_ntseq) - 3 ) ; $k = $k + 3 ) {
        my $m_codon = substr( $m_ntseq, $k, 3 );
        if ( exists( $translationTable{$m_codon} ) ) {
            $m_aaseq = $m_aaseq . $translationTable{$m_codon};
        }
        else {
            print("ERROR: $m_codon --> X\n");
            $m_aaseq = $m_aaseq . "X";
        }
    }
    my $last_codon           = "";
    my $lastCodonIsStopCodon = 0;
    $last_codon = substr( $m_ntseq, ( length($m_ntseq) - 3 ), 3 );
    if ( $last_codon eq "TGA" ) {
        $lastCodonIsStopCodon = 1;
    }
    if ( $last_codon eq "TAA" ) {
        $lastCodonIsStopCodon = 1;
    }
    if ( $last_codon eq "TAG" ) {
        $lastCodonIsStopCodon = 1;
    }
    if ( $last_codon eq "TAR" ) {
        $lastCodonIsStopCodon = 1;
    }
    if ( $last_codon eq "TRA" ) {
        $lastCodonIsStopCodon = 1;
    }
    if ( $lastCodonIsStopCodon > 0 ) {
    }
    else {
        if ( exists( $translationTable{$last_codon} ) ) {
            $m_aaseq = $m_aaseq . $translationTable{$last_codon};
        }
        else {
            print("ERROR: $last_codon --> X\n");
            $m_aaseq = $m_aaseq . "X";
        }
    }


#OUT->regular file, OUTFASTA->fasta-file


    if ( length($m_aaseq) < 10 ) {
        print OUT "$m_def\t$m_size bp\t000"
          . length($m_aaseq)
          . " aa\t$m_start..$m_stop\t$m_ntseq\t$m_aaseq\n";
    }
    elsif ( length($m_aaseq) < 100 ) {
        print OUT "$m_def\t$m_size bp\t00"
          . length($m_aaseq)
          . " aa\t$m_start..$m_stop\t$m_ntseq\t$m_aaseq\n";
    }
    elsif ( length($m_aaseq) < 1000 ) {
        print OUT "$m_def\t$m_size bp\t0"
          . length($m_aaseq)
          . " aa\t$m_start..$m_stop\t$m_ntseq\t$m_aaseq\n";
    }
    else {
        print OUT "$m_def\t$m_size bp\t"
          . length($m_aaseq)
          . " aa\t$m_start..$m_stop\t$m_ntseq\t$m_aaseq\n";
    }

#if you choose whole sequence, will give whole, otherwise default will be just the orf nucleotide sequence
    if ( $wholent > 0 ) { 
        
        print OUTFASTA ">$m_def|$m_size bp|"
          . length($m_aaseq)
          . " aa|$m_start..$m_stop\n$seq\n";
    }
    else {
        print OUTFASTA ">$m_def|$m_size bp|"
          . length($m_aaseq)
          . " aa|$m_start..$m_stop\n$m_ntseq\n";
    }
}

close(OUT);
close(OUTFASTA);
