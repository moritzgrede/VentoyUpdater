<#
.SYNOPSIS
Template for ImageUpdater scripts

.DESCRIPTION
Template for ImageUpdater scripts
#>


param (
	# Path to the USB drive containing the images
	[Parameter( Mandatory = $true )]
	[ValidateNotNullOrEmpty()]
	[string]
	$ImagePath,

	# Temporary location for downloaded files
	[Parameter( Mandatory = $true )]
	[ValidateNotNullOrEmpty()]
	[string]
	$WorkingDirectory
)
process {
	# Copy-Item -LiteralPath $Image -Destination $ImagePath
}