# Deployments

## Purpose

Provides reusable orchestration for VM provisioning, OS preparation, and service installation.

## Example contents

A shared sequence that creates a VM, prepares Windows, and configures a server role.

## Scope

Lab-specific topology and configuration belong in `SysAdminDk` repositories. Shared service code belongs in `../BuildScripts/Services`.

## Dependencies

Calls the applicable code in `../Platforms/HyperV` or `../Proxmox` and uses build scripts from the same pinned revision.
