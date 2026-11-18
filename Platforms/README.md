# Platforms

## Purpose

Houses the existing Hyper-V platform provisioning code.

## Example contents

VM, virtual disk, and virtual NIC provisioning in `HyperV`. The equivalent Proxmox code lives in `../Proxmox`.

## Scope

Guest installation belongs in `../BuildScripts`. Administration of existing hosts belongs in `InfraTools`.

## Dependencies

Provisioning requires access to the host and the applicable platform API or modules.
