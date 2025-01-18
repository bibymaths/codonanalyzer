#!\usr\bin\perl -w 

print "Enter the filename for DNA sequence: ";    ##INPUT of .fasta from user

$DNAfilename = <STDIN>;
chomp $DNAfilename;

unless ( open( DNAFILE, $DNAfilename ) ) {
    print "Cannot open file \"$DNAfilename\"\n\n";
}
@DNA = <DNAFILE>;    ##storing File Handler in an Array
close DNAFILE;

my $DNA = join( '', @DNA );    ##joining the whitespaces

$DNA =~ s/\s//g;    ##Cross checking the whitespace character in sequence

my $protein = '';   ##formatting protein
my $codon;

for ( my $i = 0 ; $i < ( length($DNA) - 2 ) ; $i += 3 ) ##$i for 1 or more times
{
    $codon = substr( $DNA, $i, 3 );
    $protein .= &codon2aa($codon);    ##checking except for newline chars
}
printf "The translated protein is : \n$protein   \n";

open( MYFILE, '>>Trans_Prot.txt' );
print MYFILE "\n>Sequence 2\n$protein \n";
close(MYFILE);

sub codon2aa                          ##DEclaring subroutine "codon2aa"
{
    my ($codon) = @_;
    $codon = uc $codon;

    my (%g) = (

        'TCA' => 'S',                 # Serine
        'TCC' => 'S',                 # Serine
        'TCG' => 'S',                 # Serine
        'TCT' => 'S',                 # Serine
        'TTC' => 'F',                 # Phenylalanine
        'TTT' => 'F',                 # Phenylalanine
        'TTA' => 'L',                 # Leucine
        'TTG' => 'L',                 # Leucine
        'TAC' => 'Y',                 # Tyrosine
        'TAT' => 'Y',                 # Tyrosine
        'TAA' => '',                  # Stop
        'TAG' => '',                  # Stop
        'TGC' => 'C',                 # Cysteine
        'TGT' => 'C',                 # Cysteine
        'TGA' => '',                  # Stop
        'TGG' => 'W',                 # Tryptophan
        'CTA' => 'L',                 # Leucine
        'CTC' => 'L',                 # Leucine
        'CTG' => 'L',                 # Leucine
        'CTT' => 'L',                 # Leucine
        'CCA' => 'P',                 # Proline
        'CCC' => 'P',                 # Proline
        'CCG' => 'P',                 # Proline
        'CCT' => 'P',                 # Proline
        'CAC' => 'H',                 # Histidine
        'CAT' => 'H',                 # Histidine
        'CAA' => 'Q',                 # Glutamine
        'CAG' => 'Q',                 # Glutamine
        'CGA' => 'R',                 # Arginine
        'CGC' => 'R',                 # Arginine
        'CGG' => 'R',                 # Arginine
        'CGT' => 'R',                 # Arginine
        'ATA' => 'I',                 # Isoleucine
        'ATC' => 'I',                 # Isoleucine
        'ATT' => 'I',                 # Isoleucine
        'ATG' => 'M',                 # Methionine
        'ACA' => 'T',                 # Threonine
        'ACC' => 'T',                 # Threonine
        'ACG' => 'T',                 # Threonine
        'ACT' => 'T',                 # Threonine
        'AAC' => 'N',                 # Asparagine
        'AAT' => 'N',                 # Asparagine
        'AAA' => 'K',                 # Lysine
        'AAG' => 'K',                 # Lysine
        'AGC' => 'S',                 # Serine
        'AGT' => 'S',                 # Serine
        'AGA' => 'R',                 # Arginine
        'AGG' => 'R',                 # Arginine
        'GTA' => 'V',                 # Valine
        'GTC' => 'V',                 # Valine
        'GTG' => 'V',                 # Valine
        'GTT' => 'V',                 # Valine
        'GCA' => 'A',                 # Alanine
        'GCC' => 'A',                 # Alanine
        'GCG' => 'A',                 # Alanine
        'GCT' => 'A',                 # Alanine
        'GAC' => 'D',                 # Aspartic Acid
        'GAT' => 'D',                 # Aspartic Acid
        'GAA' => 'E',                 # Glutamic Acid
        'GAG' => 'E',                 # Glutamic Acid
        'GGA' => 'G',                 # Glycine
        'GGC' => 'G',                 # Glycine
        'GGG' => 'G',                 # Glycine
        'GGT' => 'G',                 # Glycine
    );
    if ( exists $g{$codon} )          ##checking for key in hash table with file
    {

        return $g{$codon};

    }
    else {
        print STDERR "Bad codon \"$codon\"!!\n";
        exit;
    }
}

