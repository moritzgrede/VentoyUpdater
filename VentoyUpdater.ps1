#Requires -Version 7
#region VARIABLES
$VentoyReleaseArchive = Join-Path -Path $PSScriptRoot -ChildPath 'VentoyReleaseArchive.zip'
$VentoyRelease = Join-Path -Path ( $VentoyReleaseArchive | Split-Path -Parent ) -ChildPath ( $VentoyReleaseArchive | Split-Path -LeafBase )
$MetadataFileName = 'metadata.json'
$VentoyUpdaterLogs = @{
	'result'   = 'cli_done.txt'
	'log'      = 'cli_log.txt'
	'progress' = 'cli_percent.txt'
}
$Transcript = Join-Path -Path $PSScriptRoot -ChildPath 'transcript.log'
$GetVentoyUsb = Join-Path -Path $PSScriptRoot -ChildPath 'helper\Get-VentoyUsb.ps1'

#region FUNCTIONS
function Start-Cleanup {
	$VentoyReleaseArchive, $VentoyRelease | ForEach-Object {
		if ( ( Test-Path -LiteralPath $_ ) ) {
			Remove-Item -LiteralPath $_ -Recurse -Force
		}
	}
}

#region SCRIPT
Start-Transcript -LiteralPath $Transcript -UseMinimalHeader -Force
# Cleanup any left-over files from a previous execution
Start-Cleanup

# Find valid USB drive
try {
	$UsbDrive = &$GetVentoyUsb
} catch {
	Write-Error $_
	Stop-Transcript
	exit 10
}
Write-Host "Updating Ventoy on USB drive mounted at $( $UsbDrive )"

# Get metadata from drive
$MetadataFile = Join-Path -Path $UsbDrive -ChildPath $MetadataFileName
try {
	$Metadata = Get-Content -LiteralPath $MetadataFile -ErrorAction Stop | ConvertFrom-Json
} catch {
	Write-Error 'Error while trying to access USB metadata'
	Write-Error $_
	Stop-Transcript
	exit 10
}
Write-Host "Current installed version is $( $Metadata.version )"

# Get latest release from GitHub
$RestResult = $null
$LatestRelease = Invoke-RestMethod -Uri 'https://api.github.com/repos/ventoy/Ventoy/releases/latest' -StatusCodeVariable 'RestResult'
if ( $RestResult -ne 200 ) {
	Write-Error "Rest API call returned status code $( $RestResult )"
	Write-Error $LatestRelease
	Stop-Transcript
	exit 10
}
$LatestRelease | Add-Member -MemberType NoteProperty -Name 'version' -Value ( [version] ( $LatestRelease.tag_name -replace '[vV]', '' ) )
Write-Host "Found latest GitHub release to be `"$( $LatestRelease.name )`""
if ( [version] $Metadata.version -ge $LatestRelease.version ) {
	Write-Host 'Current version is equal to or greater than the current GitHub release'
	Stop-Transcript
	exit 0
}
Write-Host 'Download release from GitHub'
$LatestReleaseArchive = $LatestRelease.assets | Where-Object -Property 'name' -Like -Value '*windows.zip'
if ( @( $LatestReleaseArchive ).Count -ne 1 ) {
	Write-Error 'Found more than 1 release for download'
	Stop-Transcript
	exit 10
}
Invoke-RestMethod -Uri $LatestReleaseArchive.browser_download_url -OutFile $VentoyReleaseArchive -StatusCodeVariable 'RestResult'
if ( $RestResult -ne 200 ) {
	Write-Error "Rest API call returned status code $( $RestResult )"
	Write-Error $LatestRelease
	Start-Cleanup
	Stop-Transcript
	exit 10
}

# Search for and execute Ventoy installer / updater
$VentoyReleaseFiles = Expand-Archive -LiteralPath $VentoyReleaseArchive -DestinationPath $VentoyRelease -PassThru
Remove-Item -LiteralPath $VentoyReleaseArchive
$VentoyUpdater = $VentoyReleaseFiles | Where-Object -Property Name -Like -Value 'Ventoy2Disk.exe'
if ( @( $VentoyUpdater ).Count -ne 1 ) {
	Write-Error 'Could not find Ventoy installer in release'
	Start-Cleanup
	Stop-Transcript
	exit 10
}
foreach ( $Log in $VentoyUpdaterLogs.Clone().GetEnumerator() ) {
	$VentoyUpdaterLogs.($Log.Name) = Join-Path -Path $VentoyUpdater.Directory.FullName -ChildPath $Log.Value
}
Write-Host 'Starting Ventoy update'
Start-Process -FilePath $VentoyUpdater.FullName -ArgumentList "VTOYCLI /U /Drive:$( $UsbDrive )" -NoNewWindow

# Wait for the Ventoy installer / updater to complete
$Timeout = ( Get-Date ).AddMinutes( 15 )
while ( $true ) {
	if ( ( Get-Date ) -ge $Timeout ) {
		Write-Error 'Reached timeout while waiting for Ventoy to update'
		Start-Cleanup
		Stop-Transcript
		exit 10
	}
	try {
		$VentoyUpdaterProgress = ( Get-Content -LiteralPath $VentoyUpdaterLogs.progress -Raw -ErrorAction Stop ).Trim()
		Write-Progress -Activity 'Update Ventoy' -Status 'Updating' -PercentComplete $VentoyUpdaterProgress
	} catch {}
	if ( ( Test-Path -LiteralPath $VentoyUpdaterLogs.result ) ) {
		Write-Progress -Activity 'Update Ventoy' -Status 'Updating' -PercentComplete 100 -Completed
		try {
			$VentoyUpdaterResult = ( Get-Content -LiteralPath $VentoyUpdaterLogs.result -Raw -ErrorAction Stop ).Trim()
			if ( $VentoyUpdaterResult -eq 0 ) {
				Write-Host 'Ventoy update was successful'
			} else {
				Write-Error 'Ventoy update failed'
				Get-Content -LiteralPath $VentoyUpdaterLogs.log -Raw -ErrorAction SilentlyContinue | Write-Host
				Start-Cleanup
				Stop-Transcript
				exit 10
			}
		} catch {
			Write-Host 'Could not determine result of Ventoy update. Assuming that the update was successful'
		}
		break
	}
	Start-Sleep -Milliseconds 500
}

# Update metadata
Write-Host 'Updating metadata file on USB'
$Metadata.version = $LatestRelease.version.ToString()
$Metadata | ConvertTo-Json | Out-File -FilePath $MetadataFile -Force

# Exit
Start-Cleanup
Stop-Transcript
exit 0