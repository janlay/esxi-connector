#!/bin/sh

source utils.sh

init

case "$1" in
'' | 'host')
    case "$2" in
    '' | 'index')
        output_item 'esxi-host-list' 'call host-list' 'List Virtual Machines' 'Get all VMs on ESXi host'
        output_item 'esxi-host-hw' 'call host-hw' 'Get Hardware Info' 'Get Some useful hardware info'
        # output_item 'esxi-host-sw' 'call host-sw' 'Get Software Info' 'Get Some useful software info'
        output_item 'esxi-clear' 'clear' 'Clear Cache' 'Try this if you want fresh news'
        ;;
    'list')
        QUERY="$(echo "$3" | xargs)"
        output_flush
        cache 'vmsvc/getallvms'
        cat "$CACHE_FILE" | tail +2 | cut -c 1-24 | grep -i "$QUERY" | awk -f vmrc.awk
        ;;
    'hw')
        cache 'hostsvc/hosthardware' '1m'
        # Server
        extract_for 'model = "'
        TITLE="$VALUE"

        extract_for 'vendor = "'
        VENDER="$VALUE"

        extract_for 'Product ID:'
        PRODUCTID="$VALUE"

        extract_in "$(grep -B2 'Service tag' "$CACHE_FILE" | head -n1)"
        SN="$VALUE"

        output_info "$SN" "Server: $TITLE" "Vender: $VENDER, $PRODUCTID, SN: $SN"

        # CPU
        extract_in "$(grep -A5 'vim.host.CpuPackage' "$CACHE_FILE" | tail -n1)"
        TITLE="$VALUE"
        CPU="$(grep -A3 'vim.host.CpuInfo' "$CACHE_FILE" | tail -n3 | tr -d ' ' | tr '\n' ' ' | sed 's/..$//')"

        output_info "$TITLE" "CPU: $TITLE" "$CPU"

        # BIOS
        extract_for 'biosVersion = '
        VERSION="$VALUE"
        extract_for 'releaseDate = '
        RELEASEDATE="$VALUE"
        output_info "$VERSION" "BIOS Version: $VERSION" "Release date: $RELEASEDATE"

        # Memory
        MEMORY="$(grep 'memorySize' "$CACHE_FILE" | cut -d= -f2 | tr -d ' ' | sed 's/.$//')"
        MEMORY="$(echo "scale=2; $MEMORY/1024/1024/1024" | bc -l)"
        output_info "$MEMORY" "Memory Size: $MEMORY GB"

        # PCI
        PCI="$(grep -c 'vim.host.PciDevice' "$CACHE_FILE")"
        output_item 'esxi-pci' 'call host-hw-pci' "$PCI PCI Devices" 'Press Enter for all PCI devices'

        # Clock
        cache 'hardware clock get' '5s' 'esxcli'
        CLOCK="$(cat "$CACHE_FILE")"
        output_info "$CLOCK" "Clock: $CLOCK"
        ;;
    "hw-pci")
        QUERY="$(echo "$3" | xargs)"
        cache 'hostsvc/hosthardware' '1m'
        IFS=$'\n'
        IDS=($(grep ' id = ' "$CACHE_FILE" | cut -d\" -f2))
        DEVICEIDS=($(grep ' deviceId = ' "$CACHE_FILE" | cut -d= -f2 | tr -d ' ' | sed 's/.$//'))
        VENDORS=($(grep ' vendorName = ' "$CACHE_FILE" | cut -d\" -f2))
        NAMES=($(grep ' deviceName = ' "$CACHE_FILE" | cut -d\" -f2))

        i=-1
        for name in "${NAMES[@]}"; do
            i=$i+1
            if [ -n "$QUERY" ]; then
                echo "$name *!# ${VENDORS[$i]} *!# ${IDS[$i]}" | grep -i --quiet "$QUERY"
                [ $? = 1 ] && continue
            fi

            output_info "$name" "$name" "verdor: ${VENDORS[$i]}, id: ${IDS[$i]}, deviceId: ${DEVICEIDS[$i]}"
        done

    esac
    ;;
'vm')
    case "$2" in
    'index')
        output_item 'connect' "vm connect $3" 'Connect' 'Connect with VMware Remote Console'

        cache "vmsvc/power.getstate $3" '5s'
        POWERSTATUS=$(tail +2 "$CACHE_FILE")
        if [ "$POWERSTATUS" == "Powered on" ]; then
            cache "vmsvc/get.guest $3"
            output_info "$VALUE"

            extract_for 'ipAddress = "'
            output_info "$VALUE" "IP: $VALUE"

            extract_for 'guestFullName'
            output_info "$VALUE" "$VALUE"
        fi
        output_item "power-$3" "call vm-power $3" "Power Status: $POWERSTATUS" "Enter to change power status"
        output_item 'esxi-host-list' 'call host-list' 'Return to VM List' 'Get all VMs on ESXi host'
        ;;
    'power')
        cache "vmsvc/power.getstate $3" '5s'
        POWERSTATUS=$(tail +2 "$CACHE_FILE")
        output_info '' "Power Status: $POWERSTATUS"
        [ "$POWERSTATUS" == 'Powered on' ] && output_item "power-suspend-$3" "vm change-power $3 suspend" "Suspend"
        [ "$POWERSTATUS" != 'Powered on' ] && output_item "power-on-$3" "vm change-power $3 on" "Power On"
        [ "$POWERSTATUS" == 'Powered on' ] && output_item "power-shutdown-$3" "vm change-power $3 shutdown" "Shut Down Guest OS"
        [ "$POWERSTATUS" == 'Powered on' ] && output_item "power-reboot-$3" "vm change-power $3 reboot" "Restart Guest OS"
        [ "$POWERSTATUS" == 'Powered on' ] && output_item "power-off-$3" "vm change-power $3 off" "Power Off"
        [ "$POWERSTATUS" == 'Powered on' ] && output_item "power-reset-$3" "vm change-power $3 reset" "Reset"
        output_item "vm-$3" "call vm $3" 'Return to Virtual Machine' "vmid: $3"
        ;;
    'change-power')
        execute "vmsvc/power.$4 $3"
        output_message "Power operation completed: $4"
        ;;
    'connect')
        open "vmrc://$ESXI_HOST:443/?moid=$3"
        ;;
    esac
        ;;
'config')
    [ -d "$DEFAULT_CONFIG_DIR" ] || mkdir "$DEFAULT_CONFIG_DIR"
    [ -f "$DEFAULT_CONFIG_FILE" ] || tail -n +4 config-template.sh > "$DEFAULT_CONFIG_FILE"

    open -a TextEdit "$DEFAULT_CONFIG_FILE"
    output_message 'Save file and try again'
    ;;
'clear')
    [ -n "$CACHE_DIR" ] && [ -d "$CACHE_DIR" ] && rm -rf "$CACHE_DIR"
    output_message 'Cache cleared'
    ;;
'copy')
    shift
    if [ -n "$*" ]; then
        echo "$*\c" | pbcopy
        echo "Copied: $*\c"
    fi
    exit 0
    ;;
'call')
    shift
    osascript -e "tell application \"Alfred 2\" to search \"$* \""
    exit 0
    ;;
esac

output_end
