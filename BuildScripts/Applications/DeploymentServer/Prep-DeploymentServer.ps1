<# 

    Create folder structure.
    Download scripts from Github.

#>


# Path to PVE scripts and Functions.
# ------------------------------------------------------------
if ($PSScriptRoot -and $PSScriptRoot -ne "") {
    $RootPath = $PSScriptRoot
} else {
    $RootPath  = "C:\Scripts"
}


# Get the Required Scripts list
# ------------------------------------------------------------
if (-NOT (Test-Path -Path "$RootPath\DeploymentServerFiles.json")) {
    throw "Required file DeploymentServerFiles.json is missing in $RootPath"
} else {
    $RequiredScripts = Get-Content -Path "$RootPath\DeploymentServerFiles.json" | Convertfrom-Json
}


# Virtual Directory Name
# ------------------------------------------------------------
$WebLocation  = "Deployment"


# Required for unsigned scripts & modules.
# ------------------------------------------------------------
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force -Confirm:$false


# Prepare Folders
# ------------------------------------------------------------
if (-NOT (Test-Path -Path "$RootPath\Functions")) {
    New-Item -Path "$RootPath\Functions" -ItemType Directory | Out-Null
}
if (-NOT (Test-Path -Path "$RootPath\GIT-Cache")) {
    New-Item -Path "$RootPath\GIT-Cache" -ItemType Directory | Out-Null
}


# Install IIS Service
# ------------------------------------------------------------
# Optional: "Web-IP-Security", "Web-Windows-Auth"
$Features = @("Web-Server",
              "Web-WebServer",
              "Web-Common-Http",
              "Web-Default-Doc",
              "Web-Dir-Browsing",
              "Web-Http-Errors",
              "Web-Static-Content",
              "Web-Http-Redirect",
              "Web-Health",
              "Web-Http-Logging",
              "Web-Performance",
              "Web-Stat-Compression",
              "Web-Mgmt-Tools",
              "Web-Mgmt-Console"
              )
Get-WindowsFeature -name $Features | Install-WindowsFeature | Out-Null


# Get Default Site configuration
# ------------------------------------------------------------
Import-Module WebAdministration -ErrorAction Stop

$DefaultSite  = Get-ChildItem "IIS:\Sites" | Select-Object -First 1
$SiteName     = $DefaultSite.Name
$PhysicalPath = [Environment]::ExpandEnvironmentVariables($DefaultSite.physicalPath)


# Ensure IIS have been installed, and we can find the default site path.
# ------------------------------------------------------------
if ([string]::IsNullOrWhiteSpace($PhysicalPath) -or (-not (Test-Path -Path $PhysicalPath))) {
    throw "Invalid IIS physical path: $PhysicalPath"
}


# Create Virtual Directory
# ------------------------------------------------------------
$FileLocation = Join-Path -Path $PhysicalPath -ChildPath $WebLocation

if (-NOT (Test-Path "$FileLocation")) {
    New-Item -Path "$FileLocation" -ItemType Directory | Out-Null
}

$DeploymentSite = Get-WebVirtualDirectory -Site $DefaultSite.Name -Name $WebLocation -ErrorAction SilentlyContinue
if (-NOT ($DeploymentSite)) {
    New-WebVirtualDirectory -Site $DefaultSite.Name -Name $WebLocation -PhysicalPath "$FileLocation" -Force | Out-Null
}


# Allow Directory Browse
# ------------------------------------------------------------
If (-NOT ((Get-WebConfigurationProperty -Location "$($DefaultSite.Name)/$WebLocation" -filter "/system.webServer/directoryBrowse" -Name enabled).Value)) {
    Set-WebConfigurationProperty -Location "$($DefaultSite.Name)/$WebLocation" -filter "/system.webServer/directoryBrowse" -Name enabled -Value $true
}

# Add FileExtension .PS1
# ------------------------------------------------------------
$StaticContent = Get-WebConfigurationProperty -Location "$($DefaultSite.Name)/$WebLocation" -Filter "system.webServer/staticContent" -Name "."
if (-NOT ($StaticContent.Collection.fileExtension.Contains(".ps1"))) {
    Add-WebConfigurationProperty -Location "$($DefaultSite.Name)/$WebLocation" -Filter "system.webServer/staticContent" -Name "." -Value @{ fileExtension='.ps1'; mimeType='text/plain' }
}


# GIT Download
# ------------------------------------------------------------

