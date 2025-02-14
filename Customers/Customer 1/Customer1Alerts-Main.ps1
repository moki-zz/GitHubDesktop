param (
    [string]$CustomerName = "Customer1Alert-Par",  # Change this to get different customer parameters  
    [string]$ParameterBaseDir = "C:\AZM-GitHub\Customers\Customer 1\"
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
    "C:\AZM-GitHub\Alert Rule Categories\VMAlerts\VMAlerts-Main.ps1"
    # Add other category scripts here
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
