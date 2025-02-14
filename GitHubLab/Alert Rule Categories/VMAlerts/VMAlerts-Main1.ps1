param (
    [string]$LogFile = "C:\logs\AlertScriptErrors.log"
)

# Ensure log directory exists
$logDir = Split-Path -Path $LogFile
if (!(Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# Function to log errors
function Write-ErrorLog {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp ERROR: $Message" | Out-File -Append -FilePath $LogFile
    Write-Host "ERROR: $Message" -ForegroundColor Red
}

# Define script paths
$Scripts = @(
    "C:\AZM-GitHub\Alert Rule Categories\VMAlerts\VMAlertsSingle\Disk-Data Disk IOPS Consumed Percentage.ps1",
    "C:\AZM-GitHub\Alert Rule Categories\VMAlerts\VMAlertsSingle\Disk-OS Disk IOPS Consumed Percentage.ps1",
    "C:\AZM-GitHub\Alert Rule Categories\VMAlerts\VMAlertsSingle\Disk-Percentiles Free Space.ps1",
    "C:\AZM-GitHub\Alert Rule Categories\VMAlerts\VMAlertsSingle\Disk-Virtual Machines by Free Space MB.ps1",
    "C:\AZM-GitHub\Alert Rule Categories\VMAlerts\VMAlertsSingle\Memory-Percentiles Committed Bytes In Use.ps1",
    "C:\AZM-GitHub\Alert Rule Categories\VMAlerts\VMAlertsSingle\Memory-Virtual Machines by AvailableMB.ps1",
    "C:\AZM-GitHub\Alert Rule Categories\VMAlerts\VMAlertsSingle\Network-In Total.ps1",
    "C:\AZM-GitHub\Alert Rule Categories\VMAlerts\VMAlertsSingle\VM-Availability.ps1",
    "C:\AZM-GitHub\Alert Rule Categories\VMAlerts\VMAlertsSingle\VM-CPUByPercentiles.ps1",
    "C:\AZM-GitHub\Alert Rule Categories\VMAlerts\VMAlertsSingle\VM-SystemUpTime.ps1"
)

# Check if external scripts exist
foreach ($Script in $Scripts) {
    if (!(Test-Path $Script)) {
        Write-ErrorLog "Script file '$Script' not found!"
    }
}

# Execute external scripts
foreach ($Script in $Scripts) {
    try {
        Write-Host "Executing $Script..."
        & $Script
    } catch {
        Write-ErrorLog "Execution failed for script '$Script'. Error: $_"
    }
}

Write-Host "Master Script for VM Alerts Completed."
