#!/usr/bin/perl -w

open(FILE, $ARGV[0]);

while (<FILE>) {
    $line = $_;
    if ($line =~ /^#/) {
        #skip comment
        next;
    }
    elsif ($line =~ /^$/) {
        #end of instruction, start printing
      if (!defined($INSN_DOC{"Mnemonic"})) {
        next;
      }
        $tex_part_1 = <<TEX_PART_1;
\\newpage
\\HRule \\\\[0.4cm]
\\begin{minipage}{0.49\\textwidth}
\\begin{flushleft} \\Huge \\bfseries
$INSN_DOC{"Mnemonic"}
\\end{flushleft}
\\end{minipage}
\\begin{minipage}{0.49\\textwidth}
\\begin{flushright} \\Huge \\bfseries
$INSN_DOC{"Mnemonic"}
\\end{flushright}
\\end{minipage} \\\\[0.4cm]
\\HRule \\\\[1cm]
\\subsection{$INSN_DOC{"Mnemonic"}}
\\begin{center}
\\large
\\begin{tabular}{  r | l }
\\textbf{Mnemonic} & $INSN_DOC{"Mnemonic"}\\\\
\\textbf{Operand0} & $INSN_DOC{"Operand0"}\\\\
\\textbf{Operand1} & $INSN_DOC{"Operand1"}\\\\
\\textbf{Operand2} & $INSN_DOC{"Operand2"}\\\\
\\textbf{Operation} & $INSN_DOC{"Operation"}\\\\
\\textbf{Size} & $INSN_DOC{"Size"}\\\\
\\end{tabular}
\\end{center}
TEX_PART_1

        print $tex_part_1;

        $encoding = $INSN_DOC{"Encoding"};
        $encoding =~ /{([^}]+)}/;
        $encoding = $1;
        @fields = split(/,/, $encoding);
        print <<TAB_PART_1;
\\flushleft \\textbf{Description:} $INSN_DOC{"Description"}\\\\
\\flushleft \\textbf{Encoding:} \\\\
\\begin{center}
\\begin{tabular}{ | c | l | l |}
\\hline
\\cellcolor{lightgray} Bit(s) & \\cellcolor{lightgray} Field & \\cellcolor{lightgray} Value \\\\ \\hline
TAB_PART_1

        foreach $field (@fields) {
            @foos = split(/=/, $field);
            print "$foos[0] & $foos[1] & $foos[2] \\\\ \\hline\n";
        }
        print "\\end{tabular}\n\\end{center}\n";
        #clear the hash
        %INSN_DOC = ();
    }
    else {
        $line =~ s/_//g;
        $line =~ s/\$//g;
        if ($line =~ /(^[^: ]+)\s*:\s*(.+)$/) {

            $INSN_DOC{$1} = $2;
        }
    }
}


