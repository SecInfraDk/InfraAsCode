<#

    Connect to MS Eval center and download selected ISO files

#>

$ISOFiles = "C:\Scripts\Temp\ISO Files"


# Create Required folders
# ------------------------------------------------------------
if (-not (Test-Path $ISOFiles)) {
    New-Item -Path $ISOFiles -ItemType Directory -Force | Out-Null
}


# Define OS ISO files to download
# ------------------------------------------------------------
$EvalCenter = Invoke-WebRequest -Uri "https://www.microsoft.com/en-us/evalcenter" -UseBasicParsing
$EvalVersions = ($EvalCenter.links | where {$_.href -like "*evaluate-windows-server-20*"}).href | 
    ForEach-Object { [regex]::Match($_, '\d{4}(?=-|$)').Value } |
        Sort-Object -Unique
$ServerVersionsISO = $EvalVersions | Out-GridView -Title "Select the required Windows Server versions" -OutputMode Multiple


# Download Selected Media Files
# ------------------------------------------------------------
$ServerVersionsISO | Foreach {

    $Response = Invoke-WebRequest -Uri "https://www.microsoft.com/en-us/evalcenter/download-windows-server-$($_)" -UseBasicParsing
    $Source = ($response.Links | Where { $_.'aria-label' -like "*ISO*en-US*" }).href

    $Destination = Join-Path $ISOFiles "Server_$($_)_Eval.ISO"
    if (Test-Path $Destination) {
        Write-Host "ISO already exists: $Destination"
        return
    }

    if (-not $Source) {
        Write-Warning "No ISO download URL found for Windows Server $_"
        return
    }

    Start-BitsTransfer -Source $Source -Destination $Destination
}
