<# 

    Create Deployment server with.
    4 vCpu
    8Gb Ram
    100Gb Drive for OS and Scripts

    Auto Download Server 2025 Eval.
    https://software-static.download.prss.microsoft.com/dbazure/888969d5-f34g-4e03-ac9d-1f9786c66749/26100.1742.240906-0331.ge_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso
    
    Start the VM and initiate Windows Installation.

#>

# Change Execution Policy
# ------------------------------------------------------------
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force


# Import required module.
# ------------------------------------------------------------
# TODO: RepoMigration
# Replace the legacy URL with SecInfraDK/InfraModules.
# Target file: Modules/New-Unattend/Public/New-Unattend.ps1
$Script = Invoke-RestMethod -Uri "https://raw.githubusercontent.com/SysAdminDk/InfraAsCode/refs/heads/main/Modules/New-Unattend.ps1" -ErrorAction Stop -UseBasicParsing
$script.TrimStart([char]0xFEFF) | Invoke-Expression


# Name of the "Master" VM
# ------------------------------------------------------------
$VMName     = "DCDS-01"
$SelectedOS = "2025"


# Path to PVE scripts and Functions.
# ------------------------------------------------------------
$TempPath = "$($ENV:USERPROFILE)\Downloads\ISO"


# Create Required folders
# ------------------------------------------------------------
If (-Not (Test-Path "$TempPath")) {
    New-Item -Path "$TempPath" -ItemType Directory | Out-Null
}


# Download Windows Server EVAL Isos
# ------------------------------------------------------------
$Response = Invoke-WebRequest -Uri "https://www.microsoft.com/en-us/evalcenter/download-windows-server-$SelectedOS" -UseBasicParsing
$DownloadUrl = ($response.Links | Where { $_.'aria-label' -like "*ISO*en-US*" }).href

Invoke-WebRequest -Uri $DownloadUrl -OutFile "$TempPath\$SelectedOS.iso"


# Create Server VIM
# ------------------------------------------------------------
if (Test-Path "$TempPath\$SelectedOS.iso") {
	Mount-DiskImage -ImagePath "$TempPath\$SelectedOS.iso"
	$MountDrive = $((Get-DiskImage -ImagePath "$TempPath\$SelectedOS.iso" | get-volume).DriveLetter) + ":" | Out-Null
}


# Get the Windows Image Index number
# ------------------------------------------------------------
$WinVersions = Get-WindowsImage -ImagePath "$MountDrive\Sources\install.wim"
$Image = $WinVersions | Where { $_.ImageName -like "*Standard*Desktop*" }
if (-Not ($Image.ImageIndex)) {
    throw "Unable to select Image Index, please verify ISO"
}


# Create New VHDx
# ------------------------------------------------------------
$VHDFileName = $Image.ImageName -replace(" Evaluation \(Desktop Experience\)","")
$VHDXFile = Join-Path -Path $TempPath -ChildPath $($VHDFileName + ".vhdx")

if (!(Test-Path $VHDXFile)) {

	New-VHD -Path $VHDXFile -Dynamic -SizeBytes 100Gb | Out-Null
	Mount-DiskImage -ImagePath $VHDXFile | Out-Null

	$VHDXDisk = Get-DiskImage -ImagePath $VHDXFile | Get-Disk
	$VHDXDiskNumber = [string]$VHDXDisk.Number

	# Create Partitions
    # ------------------------------------------------------------
	Initialize-Disk -Number $VHDXDiskNumber -PartitionStyle GPT -Verbose
    Get-Partition -DiskNumber $VHDXDiskNumber | Remove-Partition -Confirm:$false

    $VHDXDrive1 = New-Partition -DiskNumber $VHDXDiskNumber -GptType  "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}" -AssignDriveLetter -Size 200Mb
    $VHDXDrive1 | Format-Volume -FileSystem FAT32 -NewFileSystemLabel System -Confirm:$false | Out-null

    $VHDXDrive2 = New-Partition -DiskNumber $VHDXDiskNumber -GptType "{e3c9e316-0b5c-4db8-817d-f92df00215ae}" -Size 16Mb

    $VHDXDrive3 = New-Partition -DiskNumber $VHDXDiskNumber -UseMaximumSize -AssignDriveLetter
    $VHDXDrive3 | Format-Volume -FileSystem NTFS -NewFileSystemLabel "Windows" -Confirm:$false | Out-null


    $VHDXDrive1 = Get-Partition -DiskNumber $VHDXDiskNumber -PartitionNumber $VHDXDrive1.PartitionNumber
    $VHDXVolume1 = [string]$VHDXDrive1.DriveLetter+":"

    $VHDXDrive3 = Get-Partition -DiskNumber $VHDXDiskNumber -PartitionNumber $VHDXDrive3.PartitionNumber
    $VHDXVolume3 = [string]$VHDXDrive3.DriveLetter+":"


	# Extract Server image, and apply to VHDx
    # ------------------------------------------------------------
	Expand-WindowsImage -ImagePath "$MountDrive\Sources\install.wim" -Index $($Image.ImageIndex) -ApplyPath $VHDXVolume3\ -ErrorAction Stop | Out-Null


    # Apply BootFiles
    # ------------------------------------------------------------
    $BCDBoot = "$VHDXVolume3\Windows\System32\bcdboot.exe"

    & $BCDBoot "$VHDXVolume3\Windows" /s $VHDXVolume1 /f UEFI

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Image BCDBoot failed. Trying host BCDBoot..."

        $BCDBoot = "$env:SystemRoot\System32\bcdboot.exe"

        & $BCDBoot "$VHDXVolume3\Windows" /s $VHDXVolume1 /f UEFI
    }

    if ($LASTEXITCODE -ne 0) {
        throw "BCDBoot failed with exit code 0x$('{0:X8}' -f ($LASTEXITCODE -band 0xFFFFFFFFL))"
    }

    
    # Add Required Startup Scripts
    # ------------------------------------------------------------
    if (!(Test-Path -Path "$VHDXVolume3\Scripts")) {
        New-Item -Path "$VHDXVolume3\Scripts" -ItemType Directory | Out-Null
    }


    <#
    # TODO: RepoMigration
    # Replace the legacy URL with SecInfraDK/InfraModules.
    # Target file: Modules/New-Unattend/Public/New-Unattend.ps1

    Invoke-RestMethod -Uri "https://raw.githubusercontent.com/SecInfraDk/InfraAsCode/refs/heads/main/BuildScripts/Applications/DeploymentServer/Prep-DeploymentServer.ps1" -ErrorAction Stop -UseBasicParsing `
    -OutFile "$VHDXVolume3\Scripts\Prep-DeploymentServer.ps1"

    Invoke-RestMethod -Uri "https://raw.githubusercontent.com/SecInfraDk/InfraAsCode/refs/heads/main/BuildScripts/Applications/DeploymentServer/DeploymentServerFiles.json" -ErrorAction Stop -UseBasicParsing `
    -OutFile "$VHDXVolume3\Scripts\DeploymentServerFiles.json"
    #>

    $StartUpCommands = ""


    # Add Default Unattend
    # ------------------------------------------------------------
    if (!(Test-Path -Path "$VHDXVolume3\Windows\Panther")) {
        New-Item -Path "$VHDXVolume3\Windows\Panther" -ItemType Directory | Out-Null
    }

    New-Unattend -ComputerName $VMName -FirstLogonCommands $StartUpCommands | Out-File -FilePath "$VHDXVolume3\Windows\Panther\unattend.xml" -Encoding utf8
    [XML]$Unattended = Get-Content -Path "$VHDXVolume3\Windows\Panther\unattend.xml"

    $AdminPass = (($Unattended.unattend.settings| ? {$_.pass -eq "oobeSystem"}).component | Where {$_.Name -like "*Setup"}).UserAccounts.AdministratorPassword.value

    Write-Output "-----------------------------------------------------------------"
    Write-Output ""
    Write-Output "Please take note of default credentials"
    Write-Output ""
    Write-Output "Default Username : Administrator"
    Write-Output "Default Password : $AdminPass"
    Write-Output ""
    Write-Output "-----------------------------------------------------------------"

    # Dismount
    # ------------------------------------------------------------
	Dismount-DiskImage -ImagePath $VHDXFile | Out-Null

} else {

    throw "VHDX already exists: $VHDXFile. Please cleanup before running again."

}

# Dismount ISO
# ------------------------------------------------------------
Dismount-DiskImage -ImagePath "$TempPath\$SelectedOS.iso" | Out-Null


# Get Default Switch
# ------------------------------------------------------------
$Switch = ((Get-VMSwitch)[0]).name


# Create VM
# ------------------------------------------------------------
New-VM –Name $VMName -Generation 2 –MemoryStartupBytes 2Gb -NoVHD -Path "C:\VMData" -SwitchName $Switch | Out-Null
Set-VMMemory –VMName $VMName -DynamicMemoryEnabled $true -MaximumBytes 8Gb -MinimumBytes 1Gb -StartupBytes 2Gb
SET-VMProcessor –VMName $VMName –count 4 
$VMPath = (Get-VM -Name $VMName).path
$OSVHDxFile = "$VMPath\Virtual Hard Disks\$($VMName)_Disk_0.vhdx"

New-Item -ItemType directory -Path "$VMPath\Virtual Hard Disks" | Out-Null
Move-Item -Path $VHDXFile -Destination $OSVHDxFile
Add-VMHardDiskDrive -VMName $VMName -ControllerNumber 0 -ControllerLocation 0 –Path $OSVHDxFile

Set-VM -Name $VMName -CheckpointType Disabled

Set-VMFirmware -VMName $VMName -FirstBootDevice $(Get-VMHardDiskDrive -VMName $VMName)

# Start Deployment Server
# ------------------------------------------------------------
Start-VM -Name $VMName


# Connect to Console.
# ------------------------------------------------------------
& vmconnect.exe localhost $VMName


# Get VM IP if needed for RDP
# ------------------------------------------------------------
Start-Sleep -Seconds 120
(Get-VM -Name $VMName).NetworkAdapters.IPAddresses
