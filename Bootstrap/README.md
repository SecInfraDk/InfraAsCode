# Bootstrap

## Purpose

Starts the guest configuration process after a new VM boots.

## Example contents

Retrieve machine-specific configuration and scripts, invoke the selected build steps, and resume after restarts.

## Scope

Platform repositories arrange the initial bootstrap launch. Reusable installation logic belongs in BuildScripts.

## Dependencies

Requires access to the deployment web service and a machine identity supplied by the deployment.
