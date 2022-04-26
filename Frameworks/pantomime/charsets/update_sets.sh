for I in *.txt; do
    echo $I
    openapp CharsetDecoder.app $I > `echo $I | tr a-z- A-Z_ | sed "s:\(.*\).TXT:../Source/\1.m:g"`
done
