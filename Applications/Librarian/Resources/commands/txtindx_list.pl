#!/bin/perl

$BASE_DIR = $ARGV[0];
$RECOLL_CONF = "$BASE_DIR/recoll.conf";
@PATHS = ();

if (! -d $BASE_DIR) {
  print("X:directory not specified\n");
  exit 1;
}

$cfg = "";
open(IN, "$BASE_DIR/config.plist");
while(<IN>) {
  chomp();
  $cfg .= $_;
}
close(IN);

if ($cfg eq "") {
  print("X:config not found\n");
  exit 1;
}

if ($cfg =~ m/paths\s*=\s*\((.*?)\);/) {
  @a = split(',', $1);
  foreach(@a) {
    $_ =~ s/^\s*"//;
    $_ =~ s/"\s*$//;
    push(@PATHS, $_);
  }
}

if ($#PATHS == -1) {
  print("X:nothing to list\n");
  exit 1;
}

foreach(@PATHS) {
  open(IN, "find $_ |");
  while(<IN>) {
    chomp();
    print("$_\n");
  }
  close(IN);
}
