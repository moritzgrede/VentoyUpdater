# ⚡ VentoyUpdater
Update your [Ventoy](https://www.ventoy.net/) <sup>(not affiliated)</sup> USB drive automatically.

## ⭐ How?
1. First you'll need an already set up Ventoy USB drive (follow their great [Getting Started guide](https://www.ventoy.net/en/doc_start.html))
2. Then you can set up the PowerShell script `VentoyUpdater.ps1` from this repository to automatically run whenever you deem it necessary and it will
    - Search for any removable drive labeled `Ventoy` with less than 200 GB of space
    - Check the latest [Ventoy GitHub release](https://github.com/ventoy/Ventoy/releases/latest) and compare the tagged version with the version from your USB drive
    - If the version is different, it'll download the latest release and run the Updater (on the very first run the Updater will always run because the necessary metadata file does not yet exist)
    - After a successful update the script will put / update a `metadata.json` file on the USB drive with the new version number

❗ The script will need to run elevated (as administrator) as the Ventoy Updater requires this to update.

Running the script will create a transcript called `transcript.log` in the same folder the script is located. When running as a scheduled task this can help you to keep an eye on the output of the script and any errors that may come up.

## 🧪 Integration examples

### 🕔 Windows Scheduled Tasks

As an example I have attached two Windows Scheduled Task definitions in `Examples` subfolder. You can import one of the examples in the Task Scheduler, just be sure to change the path to the folder where you downloaded / cloned this repository (change `%REPLACE WITH PATH TO FOLDER%`). The task and in general the script will have to run as an administrator as the updater can otherwise not update the USB drive.

#### `WeeklyScheduledTask.xml`

The script will be executed every Monday as soon as possible (if the start is missed, it is executed later).

#### `PnPScheduledTask.xml`

To use this task, you will first need to enable a Windows Event Log. This log will provide the necessary events to let the Scheduled Task run whenever a new USB drive is plugged in.
1. Open Event Viewer (Win + R, enter `eventvwr.msc`, press Enter **or** Right-click the Windows start menu button and select "Event Viewer")
2. Expand "Application and Service Logs"
3. Expand "Microsoft"
4. Expand "Windows"
5. Expand "DriverFrameworks-UserMode"
6. Right-click the "Operational" log
7. Select "Enable Log"

Now import the Scheduled Task and it will run whenever a USB drive is plugged in (with a 30 second delay).

## ❗ DISCLAIMER
This script is provided "as is", without warranty of any kind. Use at your own risk. The author assumes no responsibility or liability for any loss, damage, or other problems that may arise from the use, misuse, or inability to use this script. Always review and test the script in a safe environment before running it on important data.

It is strongly recommended to perform regular backups of your data to prevent any dataloss.

This script is an independent project and is not associated with, endorsed by, or otherwise affiliated with [Ventoy](https://www.ventoy.net/).

## 🚧 Work in Progress

### Feature suggestions / upcoming changes
- With an additional script it should also be possible to update images on the USB drive automatically