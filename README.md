# ESXi Connector

ESXi Connector is an Alfred workflow that provides handy tools to work together with ESXi Servers.

## Requirements

- Alfred 2 or Alfred 3 (new!)
- ESXi 6
- [Enable SSH using public key](https://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=1002866)

## Installation

Download the `ESXi Connector.alfredworkflow`, double click to install this workflow.

## Usage

Use `esxi` to get started. You'll be prompted to setup the config (just one line).

### Other keywords

- `host-hw`: Show hardware info
- `host-list`: Show all virtual machines, filter enabled
- `host-hw-pci`: Show all PCI devices, filter enabled
- `vm <vmid>`: Show and connect to a virtual machine
- `vm-power <vmid>`: Get and set power status for virtual machine


## Change log

- v1.2: Support Alfred 3
- v1.1: Support Remote Desktop Connection for Windows installed VMs
- v1.0: Initial version

---

License: MIT