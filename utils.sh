#!/bin/bash

CACHE_FILE=TBD
OUTPUT=()


cache() {
    local cachevalidin="1d"
    [ -z "$2" ] || cachevalidin="$2"
    local cmd='vim-cmd'
    [ -z "$3" ] || cmd="$3"

    local FILENAME=$(echo "$1" | tr \ / _)
    local FILEPATH="$alfred_workflow_cache/cache_$FILENAME"

    # echo "cmd: find \"$FILEPATH\" -type f -mtime +$cachevalidin -print0"
    find "$FILEPATH" -type f -mtime +$cachevalidin -print0 2> /dev/null | xargs -0 rm

    [ -f "$FILEPATH" ] || ssh $ESXI_HOST "$cmd $1" > "$FILEPATH" 2>&1
    if [ $? -ne 0 ]; then
        ERR="`cat "$FILEPATH"`"
        rm "$FILEPATH"
        output_error "Connection failed with $ESXI_HOST" "$ERR"
    fi

    CACHE_FILE="$FILEPATH"
}

execute() {
    local FILENAME=$(echo "$1" | tr \ / _)
    local FILEPATH="$alfred_workflow_cache/$FILENAME"

    ssh $ESXI_HOST "vim-cmd $1" > "$FILEPATH" 2>&1
    if [ $? -ne 0 ]; then
        output_message "Execution failed: $(cat "$FILEPATH")"
    fi
}

VALUE=""
extract_in() {
    local sp="$2"
    [ -z "$2" ] && sp='"'
    VALUE="$(echo "$1" | cut -d$sp -f2)"
}

extract_for() {
    local sp="$2"
    [ -z "$2" ] && sp='"'
    VALUE="$(grep -m 1 "$1" "$CACHE_FILE" | cut -d$sp -f2)"
}

output_start() {
    OUTPUT+=('<?xml version="1.0"?>')
    OUTPUT+=('<items>')
}

output_end() {
    OUTPUT+=('</items>')
    output_flush
}

output_message() {
    unset OUTPUT
    echo "$1"
    [ -z "$2" ] && exit 0
}

output_flush() {
    printf "%s\n" "${OUTPUT[@]}"
    unset OUTPUT
}

output_error() {
    add_entry 0 '' '' "$1" "$2" 'AlertStopIcon'
    output_end
    exit 1
}

output_warning() {
    add_entry 0 '' '' "$1" "$2" 'AlertCautionIcon'
}

output_info() {
    add_entry 1 '' "copy $1" "$2" "$3" 'ToolbarInfo'
}

output_item() {
    add_entry 1 "$1" "$2" "$3" "$4" 'icon.png'
}

add_entry() {
    [ $1 -eq 0 ] && valid=no || valid=yes
    shift
    OUTPUT+=("<item valid=\"$valid\" uid=\"$1\" arg=\"$2\">")
    OUTPUT+=("  <title>$3</title>")
    OUTPUT+=("  <subtitle>$4</subtitle>")

    local icon="$5"
    [[ $icon == *'.'* ]] || icon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/$icon.icns"
    OUTPUT+=("  <icon>$icon</icon>")
    OUTPUT+=("</item>")
}

xml_escape() {
    return "$(echo "$1" | sed -e 's~&~\&amp;~g' -e 's~<~\&lt;~g' -e 's~>~\&gt;~g' -e 's~"~\&quot;~g')"
}

if [ -z "$ESXI_HOST" ]; then
    output_start
    [ "$1" == 'config' ] && icon_file=ToolbarCustomizeIcon || icon_file=AlertStopIcon
    add_entry 1 'esxi-config' 'config' 'Host Address Required' 'Set up Environment Variable "ESXiHost" from the upper right corner of this Workflow' $icon_file
    output_end
    exit 0
fi

