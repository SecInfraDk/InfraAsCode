# InfraAsCode

## Purpose

Reusable code for provisioning virtual machines and deploying infrastructure in production and lab environments.

## Example contents

Hyper-V and Proxmox VM provisioning, service installation, configuration examples, and shared modules.

## Scope

Operations and hardening for existing environments belong in `InfraTools`. Lab topology, environment settings, and scenarios belong in `SysAdminDk` repositories.

## Dependencies

[`BuildScripts/Services`](BuildScripts/Services/) is the authoritative source for shared AD DS, DHCP, and PKI build scripts. Lab deployments use a pinned revision and supply their own parameters.
