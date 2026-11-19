# Services

## Purpose

Provides the authoritative shared installation recipes for server roles.

## Example contents

AD DS in ADDS, DHCP in DHCP, CA installation in ADCA, and supporting PKI configuration in PKI.

## Scope

Customer and lab deployments reuse these recipes with their own parameters. Role maintenance belongs in InfraTools.

## Dependencies

Runs after OS preparation. Each role defines its required modules, permissions, and installation order.
