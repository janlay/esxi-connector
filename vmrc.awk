#!/usr/bin/awk -f

BEGIN {
    FS="[[:space:]][[:space:]]+"
}

{
    system(". utils.sh; output_item 'vm-index-" $1 "' 'call vm " $1 "' '" $2 "' '" $6 ", vmid: "$1", schema: " $5 "'; output_flush")
}

END {
    if (NR == 0) {
        system(". utils.sh;output_warning 'Virtual machine not found' 'Reduce keyword and try again...';output_flush")
    }
}

