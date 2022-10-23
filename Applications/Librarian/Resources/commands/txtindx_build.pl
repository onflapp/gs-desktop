#!/bin/perl

$FILE = $ARGV[0];

$cmd = "recollindex";

if (! -d $FILE) {
  print("E:directory not specified\n");
  exit 1;
}

$cfg = "";
open(IN, "$FILE/config.plist");
while(<IN>) {
  chomp();
  $cfg .= $_;
}
close(IN);

if ($cfg eq "") {
  print("E:config not found\n");
  exit 1;
}

print("$cfg\n");
if ($cfg =~ m/paths\s*=\s*\((.*?)\);/) {
  print("[$1]\n");
}

#system($cmd, "-c", $FILE);
