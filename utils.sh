#!/bin/sh

DEFAULT_CONFIG_DIR="$HOME/.ssh"
DEFAULT_CONFIG_FILE="$DEFAULT_CONFIG_DIR/esxi"

ALFREDVERSION="2"
[ -d "/Applications/Alfred 3.app" ] && ALFREDVERSION="3"

OUTPUT=()
CACHE_DIR="$HOME/Library/Caches/com.runningwithcrayons.Alfred-$ALFREDVERSION/Workflow Data/com.janlay.esxi"
init() {
    # init caching
    [ -d "$CACHE_DIR" ] || mkdir "$CACHE_DIR"

    output_start
}

CACHE_FILE=""
cache() {
    local cachevalidin="1d"
    [ -z "$2" ] || cachevalidin="$2"
    local cmd='vim-cmd'
    [ -z "$3" ] || cmd="$3"

    local FILENAME=`echo "$1" | tr \ / _`
    local FILEPATH="$CACHE_DIR/cache_$FILENAME"

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
    local FILENAME=`echo "$1" | tr \ / _`
    local FILEPATH="$CACHE_DIR/$FILENAME"

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
    VALUE="$(cat "$CACHE_FILE" | grep -m 1 "$1" | cut -d$sp -f2)"
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
    add_entry 0 '' '' "$1" "$2" '/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertStopIcon.icns'
    output_end
    exit 1
}

output_warning() {
    add_entry 0 '' '' "$1" "$2" '/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertCautionIcon.icns'
}

output_info() {
    add_entry 1 '' "copy $1" "$2" "$3" '/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ToolbarInfo.icns'
}

output_item() {
    add_entry 1 "$1" "$2" "$3" "$4" 'icon.png'
}

add_entry() {
    local valid='yes'
    [ $1 -eq 0 ] && valid='no'
    OUTPUT+=("<item valid=\"$valid\" uid=\"$2\" arg=\"$3\">")
    OUTPUT+=("  <title>$4</title>")
    OUTPUT+=("  <subtitle>$5</subtitle>")
    OUTPUT+=("  <icon>$6</icon>")
    OUTPUT+=("</item>")
}

if [ -z "$ESXI_HOST" ] && [ "$1" != 'config' ]; then
    [ -f "$DEFAULT_CONFIG_FILE" ] && source "$DEFAULT_CONFIG_FILE"
    if [ -z "$ESXI_HOST" ]; then
        output_start
        add_entry 1 'esxi-config' 'config' 'Host Address Required' 'Press Enter to open ~/.ssh/esxi' '/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertStopIcon.icns'
        output_end
        exit 0
    fi
fi

