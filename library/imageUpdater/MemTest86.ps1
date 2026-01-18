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
	# Download & extract MemTest86
	$MemTestArchive = Join-Path -Path $WorkingDirectory -ChildPath 'memtest.zip'
	$MemTest = Join-Path -Path ( $WorkingDirectory | Split-Path -Parent ) -ChildPath ( $WorkingDirectory | Split-Path -LeafBase )
	Invoke-RestMethod -Uri 'https://www.memtest86.com/downloads/memtest86-usb.zip' -OutFile $MemTestArchive -StatusCodeVariable 'RestResult'
	if ( $RestResult -ne 200 ) {
		throw [System.Exception]::new( "Rest API call returned status code $( $RestResult )", [System.Exception]::new( $LatestRelease ) )
	}
	$MemTestFiles = Expand-Archive -LiteralPath $MemTestArchive -DestinationPath $MemTest -PassThru

	# Find & copy image
	$MemTestImage = $MemTestFiles | Where-Object -Property 'Name' -EQ -Value 'memtest86-usb.img'
	if ( @( $MemTestImage ).Count -ne 1 ) {
		throw [System.Exception]::new( 'Did not find MemTest86 image' )
	}
	Copy-Item -LiteralPath $MemTestImage -Destination ( Join-Path -Path $ImagePath -ChildPath 'MemTest86.img' ) -Force
}