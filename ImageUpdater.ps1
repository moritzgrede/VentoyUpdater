#region VARIABLES
$Transcript = Join-Path -Path $PSScriptRoot -ChildPath 'ImageUpdater.log'
$GetVentoyUsb = Join-Path -Path $PSScriptRoot -ChildPath 'library\helper\Get-VentoyUsb.ps1'
$ConfigurationFile = Join-Path -Path $PSScriptRoot -ChildPath 'ImageUpdater.json'
$ImageUpdater = Join-Path -Path $PSScriptRoot -ChildPath 'library\imageUpdater'
$TemporaryDirectory = Join-Path -Path $PSScriptRoot -ChildPath 'ImageUpdaterTemporaryFiles'

#region SCRIPT
Start-Transcript -LiteralPath $Transcript -UseMinimalHeader -Force
# Find valid USB drive
try {
	$UsbDrive = &$GetVentoyUsb
} catch {
	Write-Error $_
	Stop-Transcript
	exit 10
}

# Get ImageUpdater scripts
$ExistingImageUpdater = Get-ChildItem -LiteralPath $ImageUpdater -Filter '*.ps1' -Exclude '.template.ps1'
if ( -not $ExistingImageUpdater ) {
	Write-Error 'Could not find any ImageUpdater scripts!'
	Stop-Transcript
	exit 10
}

# Get configuration
if ( ( Test-Path -LiteralPath $ConfigurationFile ) ) {
	$Configuration = Get-Content -LiteralPath $ConfigurationFile -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
}
if ( -not $Configuration ) {
	$Choice = $Host.UI.PromptForChoice(
		'No configuration present',
		"There is no configuration present for the ImageUpdater. Do you want to create a configuration right now? The script will prompt you for all possible ImageUpdater scripts (count: $( $ExistingImageUpdater.Count )) and ask wether you want to execute them or not. Otherwise create the configuration manually and restart the script.",
		@( '&Yes, create a configuration now', '&No, create configuration manually' ),
		0
	)
	if ( $Choice -ne 0 ) { exit 0 }
	$Configuration = @()
	$YesToAll = $false
	foreach ( $Script in $ExistingImageUpdater ) {
		if ( -not $YesToAll ) {
			$Choice = $Host.UI.PromptForChoice(
				$Script.BaseName,
				"Should $( $Script.BaseName ) be added to the list of ImageUpdaters?",
				@( '&Yes', '&No', 'Yes to this and &all following', 'No to thi&s and all following' ),
				0
			)
			$YesToAll = $Choice -eq 2
		}
		if ( $Choice -eq 3 ) { break }
		if ( $YesToAll -or $Choice -in 0, 2 ) {
			$Configuration += $Script.BaseName
		}
	}
	$Configuration | ConvertTo-Json -AsArray | Out-File -LiteralPath $ConfigurationFile
}

# Create temporary directory
if ( ( Test-Path -LiteralPath $TemporaryDirectory ) ) {
	Remove-Item -LiteralPath $TemporaryDirectory -Recurse -Force
}
New-Item -ItemType 'Directory' -Path $TemporaryDirectory | Out-Null

# Run each ImageUpater script
Write-Host "Starting to update $( $Configuration.Count ) images"
$Configuration | ForEach-Object -ThrottleLimit 3 -Parallel {
	$CurrentImageUpdater = $_
	$CurrentImageUpdateFile = $using:ExistingImageUpdater | Where-Object -Property 'BaseName' -EQ -Value $CurrentImageUpdater
	if ( -not $CurrentImageUpdateFile ) {
		Write-Error "Could not find ImageUpdater $( $CurrentImageUpdater )"
		break
	}
	Write-Host "Starting updater $( $CurrentImageUpdater )"
	try {
		&$CurrentImageUpdateFile.FullName -ImagePath $using:UsbDrive -WorkingDirectory $using:TemporaryDirectory
	} catch {
		Write-Error "Error while updating $( $CurrentImageUpdater )"
		Write-Error $_
	} finally {
		Write-Host "Finished updater $( $CurrentImageUpdater )"
	}
}
Write-Host 'Finished updates'
Stop-Transcript