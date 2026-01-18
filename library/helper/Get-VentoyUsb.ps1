[OutputType( [string] )]
param ()
process {
    # Make sure that the drive is labeled "Ventoy", removable and less than 200 GB
    $UsbDrive = Get-Volume | Where-Object { $_.FileSystemLabel -eq 'Ventoy' -and $_.DriveType -eq 'Removable' -and ( $_.Size / 1gb ) -lt 200 }
    if ( @( $UsbDrive ).Count -ne 1 ) {
        throw [System.Exception]::new( 'Error while identifying USB drive' )
    }
    "$( $UsbDrive.DriveLetter ):"
}