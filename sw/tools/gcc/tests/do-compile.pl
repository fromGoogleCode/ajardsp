#!/usr/bin/perl

$workdir = "workdir";

$comp_pass_cnt = 0;
$comp_fail_cnt = 0;

system("mkdir $workdir 2> /dev/null");

if (!defined(@c_files)) {
    @c_files = glob("*.c");
}

foreach $c_file (@c_files) {
    $c_file =~ /(.+)(\.c)/;
    $base_name = $1;
    for ($optlevel = 0; $optlevel <= 4; $optlevel++) {
        $command = "ajardsp-gcc -O$optlevel -S $c_file -o $workdir/$base_name-O$optlevel.S";
        if (0 == system($command . "> /dev/null")) {
            $comp_pass_cnt++;
            printf("%-64s [PASSED]\n", "Compiling (-O$optlevel) '$c_file'");
        }
        else {
            $comp_fail_cnt++;
            printf("%-64s [->FAILED<-]\n", "Compiling (-O$optlevel) '$c_file'");
            print "Command:\n$command\n";
        }
    }
}

printf("\nStatistics:\n" .
       "Compilation  %3d passed, %3d failed\n\n",
       $comp_pass_cnt, $comp_fail_cnt);

