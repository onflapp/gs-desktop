#!/bin/perl

$BASE_DIR = $ARGV[0];
$QUERY = $ARGV[1];

$cmd = "recollq";

if (! -d $BASE_DIR) {
  print("X:file not found\n");
  exit 1;
}

if ($QUERY eq "") {
  print("X:no query specified\n");
  exit 1;
}

open(IN, "$cmd -c \"$BASE_DIR\" -A \"$QUERY\" |");
while(<IN>) {
  chomp();
  if (m/^(\w+\/\w+)\s+\[(.*?)\]\s+\[(.*?)\]/) {
    $mine = $1;
    $url = $2;
    $title = $3;
    $abstract = "";
    $in_abstract = 0;

    $title = "Unknown" if ($title eq "");
  }
  elsif (m/^ABSTRACT/) {
    $in_abstract = 1;
  }
  elsif (m/^\/ABSTRACT/) {
    print("$title\n");
    print("$url\n");
    print("\n");

    $url = "";
    $in_abstract = 0;
  }
  elsif ($url ne "" && $in_abstract) {
    $abstract .= "$_\n";
  }
}
close(IN);
