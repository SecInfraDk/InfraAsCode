# InfraAsCode

## Purpose

Builds operating systems, server roles, and applications inside provisioned machines.

## Example contents

Bootstrap, OS preparation, role installation, application installation, and guest deployment sequences.

## Scope

Hypervisor operations belong in HyperVAsCode, ProxmoxAsCode, or VMwareAsCode. Customer and lab deployments supply their own environment data.

## Dependencies

The deployment service supplies configuration and a pinned revision of this repository. Shared modules come from InfraModules when required.
