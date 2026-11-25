# Required for unsigned scripts & modules.
# ------------------------------------------------------------
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force -Confirm:$false


# Path to PVE scripts and Functions.
# ------------------------------------------------------------
$RootPath  = "C:\Scripts"


# JSON directory Path
# ------------------------------------------------------------
Import-Module WebAdministration -ErrorAction Stop

$DefaultSite  = Get-ChildItem "IIS:\Sites" | Select-Object -First 1
$SiteName     = $DefaultSite.Name
$PhysicalPath = [Environment]::ExpandEnvironmentVariables($DefaultSite.physicalPath)

if ([string]::IsNullOrWhiteSpace($PhysicalPath) -or (-not (Test-Path -Path $PhysicalPath))) {
    throw "Invalid IIS physical path: $PhysicalPath"
}

$JSONRoot = Join-Path -Path $PhysicalPath -ChildPath "\Deployment\ConfigFiles"
if (-NOT (Test-Path -Path "$JSONRoot\JSON")) {
    New-Item -Path "$JSONRoot\JSON" -ItemType Directory | Out-Null
}


# Import Shared modules
# ------------------------------------------------------------
# Rember to update the PATH
Get-ChildItem -Path $RootPath -Recurse -File -Filter "*.psm1" |
    ForEach-Object { Import-Module -Name $_.FullName -Force }


# Import master config
# ------------------------------------------------------------
$MasterConfigFile = Get-ChildItem -Path $RootPath -Recurse -File -Filter "MasterServerConfig.json"
$MasterConfig = Get-Content -Path $MasterConfigFile.FullName | ConvertFrom-Json


# Get New Domain Information
# ------------------------------------------------------------
$NewDomainName   = Read-Host -Prompt "Active Directory Doamin Name (test.domain.tld)"
$NewDomainSubNet = Read-Host -Prompt "IP Subnet (10.10.10.0/24)"
$NewJoinPassword = (-join ((48..57) + (65..90) + (97..122) | Get-Random -Count 25 | ForEach-Object {[char]$_}))


# Select server type to add
# ------------------------------------------------------------
$SelectedServers  = @()
$SelectedServers += $MasterConfig | Select-Object Name,Description | Where {$_.Name -notlike "*NODE*"} | Out-GridView -Title "Select servers to add to new domain" -OutputMode Multiple


Foreach ($Server in $SelectedServers.Name) {

    $ServerData = $MasterConfig | Where {$_.Name -eq $Server}

    # Get IP addr from server master data, and replace with default network definition
    $NewNetworkAddress = (($NewDomainSubNet -Split("\."))[0..2]) -join(".")
    $NetworkData       = $ServerData.Network.IPv4Address -split("\.")
    $ServerAddress     = ($NetworkData)[-1]
    $OldNetworkAddress = ($NetworkData[0..2]) -join(".")

    # Update the Server Values
    $ServerData.Network.IPv4Address     = ($NewNetworkAddress, $ServerAddress) -join(".")
    $ServerData.Network.PhysicalAddress = ("00","00") + (((IP2Mac -IpAddress $ServerData.Network.IPv4Address) -Split("-"))[2..5]) -Join("-")
    $ServerData.Network.DefaultGateway  = ($NewNetworkAddress, "1") -join(".")

    # Update DNS servers
    $ServerData.Network.DNSServers = $ServerData.Network.DNSServers -replace "^$([regex]::Escape($OldNetworkAddress))\.(\d+)$", "$NewNetworkAddress.`$1"

    # Update Domain Value
    if ($ServerData.DomainName -ne $null) {
        $ServerData.DomainName = $NewDomainName
    }

    # Update Domain Join values
    $ServerData.JoinOptions.UserDNSDomain = $NewDomainName
    $ServerData.JoinOptions.UserDomain    = ($NewDomainName -split("\."))[0]
    $ServerData.JoinOptions.Password      = $NewJoinPassword

    if (-NOT (Test-Path -Path "$JSONRoot\JSON\$($ServerData.Network.PhysicalAddress).json")) {
        $ServerData | ConvertTo-Json -Depth 5 | Out-File -FilePath "$JSONRoot\JSON\$($ServerData.Network.PhysicalAddress).json" -Encoding utf8
    } else {
        Write-Warning "The server $($ServerData.Name).$($ServerData.JoinOptions.UserDNSDomain) already exist"
    }
}

<#
# Create selected servers
# Change to Universal CreateVM script
# ------------------------------------------------------------
switch(Prompt-YesNo -Title "Create Servers" -Message "Execute the Create-PVEServers script ?")
{
	0 { }
	1 { 
        $CreateVM = Get-ChildItem -Path $RootPath -Recurse -File -Filter "Create-PVEVMs.ps1"
        & $CreateVM.FullName
      }
}
#>
