#!/usr/bin/awk -f

BEGIN {
    FS="[ \t]{2,}"
}

{
    system(". utils.sh;output_item vm-"$1" call\\ vm\\ "$1" '"$2"' 'vmid:\ "$1"';output_flush")
}

END {
    if (NR == 0) {
        system(". utils.sh;output_warning 'Virtual machine not found' 'Reduce keyword and try again...';output_flush")
    }
}

