# ESXi Connector

ESXi Connector is an Alfred workflow that provides handy tools to work together with ESXi Servers.

## Requirements

- Alfred 3+
- ESXi 6.x / 7.x
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
- v1.3: Improve information display of virtual machines, especially for Windows
- v1.2.3: Support Alfred 4 and future versions, drop support for Alfred 2
- v1.2.2: Improvements and bug fix
- v1.2.1: Minor bug fix
- v1.2: Support Alfred 3
- v1.1: Support Remote Desktop Connection for Windows installed VMs
- v1.0: Initial version

---

License: MIT
