#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
# ============================================================
# Script: codon.pl
# Author: Abhinav Mishra <mishraabhinav36@gmail.com>
# Date:   2025
# Copyright (c) 2025 Abhinav Mishra. All rights reserved.
# License: MIT (see LICENSE file in repository root)
# GCP: Perl5 (GNU Coding Practices for Perl5)
# ============================================================
use Carp;
use POSIX qw(floor);

# — full codon→AA map (standard) —
my %c2aa = (
  # Phenylalanine
  ttt => 'F', ttc => 'F',
  # Leucine
  tta => 'L', ttg => 'L', ctt => 'L', ctc => 'L', cta => 'L', ctg => 'L',
  # Isoleucine & Methionine
  att => 'I', atc => 'I', ata => 'I', atg => 'M',
  # Valine
  gtt => 'V', gtc => 'V', gta => 'V', gtg => 'V',

  # Serine
  tct => 'S', tcc => 'S', tca => 'S', tcg => 'S', agt => 'S', agc => 'S',
  # Proline
  cct => 'P', ccc => 'P', cca => 'P', ccg => 'P',
  # Threonine
  act => 'T', acc => 'T', aca => 'T', acg => 'T',
  # Alanine
  gct => 'A', gcc => 'A', gca => 'A', gcg => 'A',

  # Tyrosine & Stop
  tat => 'Y', tac => 'Y', taa => '*', tag => '*',
  # Histidine & Glutamine
  cat => 'H', cac => 'H', caa => 'Q', cag => 'Q',
  # Asparagine & Lysine
  aat => 'N', aac => 'N', aaa => 'K', aag => 'K',
  # Aspartate & Glutamate
  gat => 'D', gac => 'D', gaa => 'E', gag => 'E',

  # Cysteine, Tryptophan & Stop
  tgt => 'C', tgc => 'C', tga => '*', tgg => 'W',
  # Arginine
  cgt => 'R', cgc => 'R', cga => 'R', cgg => 'R', aga => 'R', agg => 'R',
  # Glycine
  ggt => 'G', ggc => 'G', gga => 'G', ggg => 'G',
);

# sanity check: should be exactly 64 codon→AA pairs
{
    my $n_c2aa = scalar keys %c2aa;
    croak "c2aa map wrong size: found $n_c2aa pairs (should be 64)\n"
        unless $n_c2aa == 64;
}

# build AA→codon groups
my %aa2c;
while ( my ( $cd, $aa ) = each %c2aa ) {
    push @{ $aa2c{$aa} }, $cd;
}

# Helper: compute one Fk-average map entry (extracted to silence map-block policy)
sub _fk_avg_entry {
    my ($k, $fk_ref) = @_;
    my $arr = $fk_ref->{$k} || [];
    my $sum = 0;
    $sum += $_ for @{$arr};
    my $avg = @{$arr} ? $sum / @{$arr} : 0;
    return ( $k => sprintf( "%.4f", $avg ) );
}

# _parse_input: slurp FASTA, strip headers & non-ACGT, return lc seq
sub _parse_input {
    my ($infile) = @_;
    my $raw;
    {
        open my $IN, '<:encoding(UTF-8)', $infile or croak $!;
        local $/ = undef;    # slurp mode, scoped to this block
        $raw = <$IN>;
        close $IN;
    }
    $raw =~ s/ > .*? \n //gsx;    # strip FASTA header lines
    $raw =~ s/ [^ACGTacgt] //gx;   # strip non-ACGT characters
    return lc $raw;
}

# _compute_nt: nucleotide counts, GC/AT%, skews, dinucleotides
sub _compute_nt {
    my ($seq, $len) = @_;

    # — 1) mono‐nuc counts, GC/AT% —
    my %nt;
    $nt{$_}++ for split //, $seq;
    my $A = $nt{a} || 0;
    my $T = $nt{t} || 0;
    my $G = $nt{g} || 0;
    my $C = $nt{c} || 0;
    my $GCpct  = $len ? sprintf( "%.2f", ( $G + $C ) / $len * 100 ) : 0;
    my $ATpct  = $len ? sprintf( "%.2f", ( $A + $T ) / $len * 100 ) : 0;

    # — 2) skews —
    my $GCskew = ( $G + $C ) ? sprintf( "%.3f", ( $G - $C ) / ( $G + $C ) ) : 'NA';
    my $ATskew = ( $A + $T ) ? sprintf( "%.3f", ( $A - $T ) / ( $A + $T ) ) : 'NA';

    # — 3) dinucleotide counts —
    my %di;
    while ( $seq =~ / (..) /gx ) { $di{$1}++ }    # overlapping dinucleotides

    return (
        A => $A, T => $T, G => $G, C => $C,
        GCpct  => $GCpct,  ATpct  => $ATpct,
        GCskew => $GCskew, ATskew => $ATskew,
        di     => \%di,
    );
}

# _compute_codon_stats: codon counts, RSCU, and ENc (Wright 1990)
sub _compute_codon_stats {
    my ($cods_ref) = @_;

    # — 4) codon counts —
    my %codon;
    $codon{$_}++ for @{$cods_ref};

    # RSCU: observed / (group_total / Ncodons_in_group)
    my %RSCU;
    while ( my ( $aa, $list ) = each %aa2c ) {
        my $sum = 0;
        $sum += ( $codon{$_} || 0 ) for @{$list};
        my $n_syn = @{$list};    # synonymous codon count in this group
        next if $aa eq '*' || !$sum;
        for my $cd ( @{$list} ) {
            $RSCU{$cd} = sprintf( "%.2f", ( $codon{$cd} || 0 ) * $n_syn / $sum );
        }
    }

    # ENc: F_k = (Sigma n_i^2 - N) / (N(N-1))
    # ENc = 2 + 9/F2 + 1/F3 + 5/F4 + 3/F6
    my %Fk;
    for my $aa ( qw(P Gly Ala Pro Thr Val Leu Ser Arg Ile Met Tyr His Gln Asn Lys Asp Glu Cys Trp Phe) ) {
        my $group = $aa2c{$aa} or next;
        my $k     = @{$group};
        next if $k < 2;
        my $N   = 0;
        my $num = 0;
        for my $cd ( @{$group} ) {
            my $n_count = $codon{$cd} || 0;    # count for this codon
            $N   += $n_count;
            $num += $n_count * $n_count;
        }
        next if $N < 2;
        $Fk{$k} ||= [];
        push @{ $Fk{$k} }, ( $num - $N ) / ( $N * ( $N - 1 ) );
    }

    # build Fk averages as a proper hash
    my %Fk_avg = map { _fk_avg_entry( $_, \%Fk ) } keys %Fk;

    # ensure we never divide by zero
    for my $k ( 2, 3, 4, 6 ) {
        $Fk_avg{$k} //= 1;
    }

    my $Enc = sprintf( "%.2f",
          2
        + 9 / $Fk_avg{2}
        + 1 / $Fk_avg{3}
        + 5 / $Fk_avg{4}
        + 3 / $Fk_avg{6}
    );

    return ( codon => \%codon, RSCU => \%RSCU, Enc => $Enc );
}

# _find_orfs: ORF statistics (start/stop counts, lengths, max, avg)
sub _find_orfs {
    my ($seq, $len, $codon_ref) = @_;

    # — 6) ORF stats —
    my $start_ct = $codon_ref->{atg} || 0;
    my $stop_ct  = ( $codon_ref->{taa} || 0 )
                 + ( $codon_ref->{tag} || 0 )
                 + ( $codon_ref->{tga} || 0 );
    my @orf_lens;
    for my $frame ( 0, 1, 2 ) {
        my $i = $frame;
        while ( $i < $len - 2 ) {
            if ( substr( $seq, $i, 3 ) eq 'atg' ) {
                for ( my $j = $i + 3; $j < $len - 2; $j += 3 ) {
                    my $cd = substr( $seq, $j, 3 );
                    if ( $cd =~ / ^ (taa|tag|tga) $ /x ) {    # stop codon
                        push @orf_lens, ( $j + 3 - $i );
                        last;
                    }
                }
                $i += 3;
            }
            else { $i++ }
        }
    }
    my $max_orf = @orf_lens ? ( sort { $b <=> $a } @orf_lens )[0] : 0;
    my $total_orf_len = 0;
    $total_orf_len += $_ for @orf_lens;
    my $avg_orf = @orf_lens ? sprintf( "%.1f", $total_orf_len / @orf_lens ) : 0;

    return (
        start_ct => $start_ct,
        stop_ct  => $stop_ct,
        orf_lens => \@orf_lens,
        max_orf  => $max_orf,
        avg_orf  => $avg_orf,
    );
}

# _sliding_gc: sliding-window GC% (window = 100 nt)
sub _sliding_gc {
    my ($seq, $len) = @_;

    # — 7) sliding‐window GC% —
    my $w = 100;
    my @win_gc;
    for my $i ( 0 .. $len - $w ) {
        my $sub = substr( $seq, $i, $w );
        my $g   = ( $sub =~ tr/g// ) + ( $sub =~ tr/c// );
        push @win_gc, sprintf( "%d–%d: %.1f%%", $i + 1, $i + $w, $g / $w * 100 );
    }
    return @win_gc;
}

# _compute_entropy: 3-mer Shannon entropy
sub _compute_entropy {
    my ($seq, $len) = @_;

    # — 8) 3-mer Shannon entropy —
    my %tri;
    while ( $seq =~ / (...) /gx ) { $tri{$1}++ }    # 3-mer counts
    my $total = $len - 2;
    my $H     = 0;
    for my $n_tri ( values %tri ) {
        my $p = $n_tri / $total;
        $H -= $p * log($p) / log(2) if $p > 0;
    }
    return sprintf( "%.4f", $H );
}

# _build_report: assemble all metrics into a printable string
sub _build_report {
    my ($r) = @_;
    my @out;

    push @out, <<"END_HDR";
INPUT:
  length:    $r->{len}
  codons:    $r->{n_codon}

NUCLEOTIDE COUNTS & %:
  A=$r->{A}  T=$r->{T}  G=$r->{G}  C=$r->{C}
  GC%= $r->{GCpct}  AT%= $r->{ATpct}
  GC skew= $r->{GCskew}  AT skew= $r->{ATskew}

DINUCLT COUNT:
END_HDR

    for my $di ( sort keys %{ $r->{di} } ) {
        push @out, sprintf( "  %s: %d\n", uc $di, $r->{di}{$di} );
    }

    push @out, "\nCODON COUNTS:\n";
    for my $c ( sort keys %{ $r->{codon} } ) {
        push @out, sprintf( "  %s: %5d\n", uc $c, $r->{codon}{$c} );
    }

    push @out, "\nRSCU:\n";
    for my $c ( sort keys %{ $r->{RSCU} } ) {
        push @out, sprintf( "  %s: %5.2f\n", uc $c, $r->{RSCU}{$c} );
    }
    push @out, "\nEffective Number of Codons (ENc): $r->{Enc}\n";

    push @out, "\nAMINO-ACID COMPOSITION:\n";
    for my $aa ( sort keys %{ $r->{aa} } ) {
        my $pct = $r->{n_codon}
            ? sprintf( "%.2f", $r->{aa}{$aa} / $r->{n_codon} * 100 )
            : 0;
        push @out, sprintf( "  %s: %5d (%.2f%%)\n", $aa, $r->{aa}{$aa}, $pct );
    }

    push @out, "\nORF STATISTICS:\n";
    push @out, "  start codons (ATG): $r->{start_ct}\n";
    push @out, "  stop  codons (TAA/TAG/TGA): $r->{stop_ct}\n";
    push @out, "  ORFs found: " . scalar( @{ $r->{orf_lens} } ) . "\n";
    push @out, "  longest ORF: $r->{max_orf} nt\n";
    push @out, "  average ORF: $r->{avg_orf} nt\n";

    push @out, "\nSLIDING‐WINDOW GC% (w=100):\n";
    push @out, "  $_\n" for @{ $r->{win_gc} };

    push @out, "\n3-MER SHANNON ENTROPY: $r->{H} bits\n";

    return join '', @out;
}

# _write_output: write report string to file (brief open/close)
sub _write_output {
    my ($outfile, $content) = @_;
    open my $OUT, '>:encoding(UTF-8)', $outfile or croak $!;
    print $OUT $content;
    close $OUT;
    return;
}

# main: orchestrate pipeline
sub main {
    my $in  = shift @ARGV or croak "Usage: $0 <in.fasta> [out.txt]\n";
    my $out = shift @ARGV or croak "Usage: $0 <in.fasta> [out.txt]\n";

    my $seq     = _parse_input($in);
    my $len     = length $seq;
    my @cods    = ( $seq =~ / (...) /gx );    # split into codons
    my $n_codon = @cods;

    my %nt = _compute_nt( $seq, $len );
    my %cs = _compute_codon_stats( \@cods );

    # — 5) AA composition —
    my $prot = join '', map { $c2aa{$_} || 'X' } @cods;
    my %aa;
    $aa{$_}++ for split //, $prot;

    my %orfs   = _find_orfs( $seq, $len, $cs{codon} );
    my @win_gc = _sliding_gc( $seq, $len );
    my $H      = _compute_entropy( $seq, $len );

    my %results = (
        len     => $len,
        n_codon => $n_codon,
        %nt,
        codon   => $cs{codon},
        RSCU    => $cs{RSCU},
        Enc     => $cs{Enc},
        aa      => \%aa,
        %orfs,
        win_gc  => \@win_gc,
        H       => $H,
    );

    _write_output( $out, _build_report( \%results ) );
    return;
}

main() if !caller;

__END__

=head1 NAME

codon.pl - Compute codon usage and sequence composition metrics from a DNA FASTA record

=head1 SYNOPSIS

  perl codon.pl <in.fasta> <out.txt>

=head1 DESCRIPTION

Reads a DNA FASTA input, normalizes sequence content to A/C/G/T, and reports
nucleotide composition, codon counts, RSCU, ENc, amino-acid composition,
ORF summary statistics, sliding-window GC%, and 3-mer Shannon entropy.

=head1 OPTIONS

=over 4

=item B<< <in.fasta> >>

Input FASTA file.

=item B<< <out.txt> >>

Output text file with metrics.

=back

=head1 INPUT/OUTPUT

Input:

- Single-record DNA FASTA file.

Output:

- Plain text metrics report.

=head1 AUTHOR

Abhinav Mishra E<lt>mishraabhinav36@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025 Abhinav Mishra.

Distributed under the BSD 3-Clause License.

=cut
