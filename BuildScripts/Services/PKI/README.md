# PKI

## Purpose

Authoritative source for shared PKI build scripts using Active Directory Certificate Services (AD CS).

## Example contents

Installation and baseline configuration of a root CA or issuing CA according to the chosen architecture.

## Scope

Certificate monitoring and renewal belong in `InfraTools/PKI`. Manage private keys and credentials outside the repository.

## Dependencies

Requires a provisioned Windows Server and CA parameters. An enterprise CA requires AD DS. A subordinate CA requires approval from its parent CA.
