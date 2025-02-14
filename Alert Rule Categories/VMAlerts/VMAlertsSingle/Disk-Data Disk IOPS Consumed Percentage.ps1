param (
    [string]$ParameterFile,
    [string]$LogFile = "C:\logs\AlertScriptErrors.log"
)

# Validate Parameter File
if (-not $ParameterFile -or !(Test-Path $ParameterFile)) {
    Write-Host "ERROR: Parameter file '$ParameterFile' not found!" -ForegroundColor Red
    return
}

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

# Load JSON parameters
try {
    $Parameters = Get-Content $ParameterFile | ConvertFrom-Json
} catch {
    Write-ErrorLog "Failed to parse JSON file. Check the syntax of '$ParameterFile'!"
    return
}

# Validate required parameters
if (-not $Parameters.PSObject.Properties["ClNm"] -or 
    -not $Parameters.PSObject.Properties["resourceGroupName"] -or 
    -not $Parameters.PSObject.Properties["actionGroupId"]) {
    Write-ErrorLog "Missing required parameters in JSON file!"
    return
}

# Define variables
$alertRuleNamePrefix = "VM - Disk - Data Disk IOPS Consumed Percentage - azm "
$Customer = $Parameters.ClNm

# Retrieve Virtual Machines
try {
    $vms = Get-AzVM
} catch {
    Write-ErrorLog "Failed to retrieve virtual machines!"
    return
}

# Check if any Virtual Machines were found
if ($vms.Count -eq 0) {
    Write-ErrorLog "No Virtual Machines found in the subscription!"
    return
}

# Loop through Virtual Machines and create metric alert rules
foreach ($vm in $vms) {
    try {
        # Create the metric alert condition
        $condition = New-AzMetricAlertRuleV2Criteria `
            -MetricName "Data Disk IOPS Consumed Percentage" `
            -TimeAggregation "Maximum" `
            -Operator "GreaterThan" `
            -Threshold 99

        # Define alert rule name based on the Virtual Machine name
        $alertRuleName = "$alertRuleNamePrefix-$($vm.Name)"

        # Create the alert rule
        Add-AzMetricAlertRuleV2 -Name $alertRuleName `
            -ResourceGroupName $Parameters.resourceGroupName `
            -WindowSize 00:05:00 `
            -Frequency 00:05:00 `
            -TargetResourceId $vm.Id `
            -Condition $condition `
            -ActionGroupId $Parameters.actionGroupId `
            -Severity 4 `
            -Description "Client Name: $Customer - Monitoring Data Disk IOPS Consumed Percentage for VM $($vm.Name)"

        Write-Host "SUCCESS: Alert rule '$alertRuleName' created successfully." -ForegroundColor Green
    } catch {
        Write-ErrorLog "Failed to create alert rule for VM '$($vm.Name)'. Error: $_"
    }
}
