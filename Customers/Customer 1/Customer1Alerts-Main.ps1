param (
    [string]$CustomerName = "Customer1Alert-Par",  
    [string]$ParameterBaseDir = "$PSScriptRoot/"
)

# Construct parameter file path dynamically
$ParameterFile = "$ParameterBaseDir$CustomerName.json"

# Validate parameter file
if (!(Test-Path $ParameterFile)) {
    Write-Host "ERROR: Parameter file '$ParameterFile' not found!" -ForegroundColor Red
    return
}

# Load parameters from JSON file
$Parameters = Get-Content $ParameterFile | ConvertFrom-Json

# Set Azure Context
Set-AzContext -SubscriptionId $Parameters.subscriptionId

# Define Alert Rule Category Scripts
$AlertCategories = @(
    "$PSScriptRoot/../../Alert Rule Categories/VMAlerts/VMAlerts-Main.ps1"
)

# Execute Each Alert Rule Category Script
foreach ($Script in $AlertCategories) {
    if (Test-Path $Script) {
        Write-Host "Executing $Script with $ParameterFile..."
        & $Script -ParameterFile $ParameterFile
    } else {
        Write-Host "ERROR: Script file '$Script' not found!" -ForegroundColor Red
    }
}

Write-Host "Master Script Execution Completed."
