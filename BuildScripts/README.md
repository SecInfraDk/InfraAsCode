# BuildScripts

## Purpose

Installs and configures the operating system and server roles inside a provisioned VM.

## Example contents

Windows baseline configuration in `OperatingSystem` and AD DS, DHCP, and PKI installation in `Services`.

## Scope

VM provisioning belongs in `Platforms/HyperV` and `Proxmox`. Operations for existing roles belong in `InfraTools`.

## Dependencies

Run after VM provisioning with the permissions, modules, and parameters required by the script.
