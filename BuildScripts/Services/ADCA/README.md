# ADCA

## Purpose

Authoritative source for shared AD CS certification authority installation scripts.

## Example contents

Root and issuing CA installation and baseline configuration in ADCA-01.ps1 and the existing temporary variant.

## Scope

CA installation logic is maintained here. PKI holds supporting configuration that reuses these builds. Operational PKI tools belong in InfraTools/PKI.

## Dependencies

Requires Windows Server and CA parameters. Enterprise CA installation requires AD DS. Subordinate CAs require their parent CA's approval.
