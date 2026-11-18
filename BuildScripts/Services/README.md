# Services

## Purpose

Provides reusable installation scripts for Windows Server roles. This is the authoritative source for AD DS, DHCP, and PKI builds.

## Example contents

Role-specific scripts in `ADDS`, `DHCP`, `DNS`, `FileServices`, `PKI`, and `RDS`.

## Scope

Deployments supply environment settings and lab topology. Ongoing operations and remediation belong in `InfraTools`.

## Dependencies

Hyper-V and Proxmox deployments provision the VM, then invoke a pinned revision of the service script with environment-specific parameters.
