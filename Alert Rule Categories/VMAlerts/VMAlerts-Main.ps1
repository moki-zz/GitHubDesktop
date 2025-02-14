param (
    [string]$ParameterFile
)

# Validate parameter file
if (!(Test-Path $ParameterFile)) {
    Write-Host "ERROR: Parameter file '$ParameterFile' not found!" -ForegroundColor Red
    return
}

# Load parameters
$Parameters = Get-Content $ParameterFile | ConvertFrom-Json

# Set Context
Set-AzContext -SubscriptionId $Parameters.subscriptionId

# Define Individual Alert Scripts
$ScriptPaths = @(
    "https://github.com/moki-zz/GitHubDesktop/blob/main/Alert%20Rule%20Categories/VMAlerts/VMAlertsSingle/Disk-Data%20Disk%20IOPS%20Consumed%20Percentage.ps1"
)

# Loop through scripts and execute
foreach ($Script in $ScriptPaths) {
    if (Test-Path $Script) {
        Write-Host "Executing: $Script..."
        & $Script -ParameterFile $ParameterFile
    } else {
        Write-Host "ERROR: Script file '$Script' not found!" -ForegroundColor Red
    }
}

Write-Host "VM Alerts Execution Completed."
