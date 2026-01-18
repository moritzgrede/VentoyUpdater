# ⚡ VentoyUpdater
Update your [Ventoy](https://www.ventoy.net/) <sup>(not affiliated)</sup> USB drive automatically.

## ⭐ How?
1. First you'll need an already set up Ventoy USB drive (follow their great [Getting Started guide](https://www.ventoy.net/en/doc_start.html))
2. Then you can set up the PowerShell script `VentoyUpdater.ps1` from this repository to automatically run whenever you deem it necessary and it will
    - Search for any removable drive labeled `Ventoy` with less than 200 GB of space
    - Check the latest [Ventoy GitHub release](https://github.com/ventoy/Ventoy/releases/latest) and compare the tagged version with the version from your USB drive
    - If the version is different, it'll download the latest release and run the Updater (on the very first run the Updater will always run because the necessary metadata file does not yet exist)
    - After a successful update the script will put / update a `metadata.json` file on the USB drive with the new version number

## ❗ DISCLAIMER
This script is provided "as is", without warranty of any kind. Use at your own risk. The author assumes no responsibility or liability for any loss, damage, or other problems that may arise from the use, misuse, or inability to use this script. Always review and test the script in a safe environment before running it on important data.

It is strongly recommended to perform regular backups of your data to prevent any dataloss.

## 🚧 Work in Progress

### Feature suggestions / upcoming changes
- With an additional script it should also be possible to update images on the USB drive automatically