param (
    [string]$ParameterFile = "C:\samples\OCD\OCDAlert-Par.json",
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

# Check if parameter file exists
if (!(Test-Path $ParameterFile)) {
    Write-ErrorLog "Parameter file '$ParameterFile' not found!"
    return  # Prevents unexpected session termination
}

# Try loading JSON parameters
try {
    $Parameters = Get-Content $ParameterFile | ConvertFrom-Json
} catch {
    Write-ErrorLog "Failed to parse JSON file. Check the syntax of '$ParameterFile'!"
    return
}

# Validate required parameters exist in the JSON file
if (-not $Parameters.PSObject.Properties["ClNm"] -or 
    -not $Parameters.PSObject.Properties["resourceGroupName"] -or 
    -not $Parameters.PSObject.Properties["actionGroupId"] -or
    -not $Parameters.PSObject.Properties["subscriptionId"]) {
    Write-ErrorLog "Missing required parameters in JSON file!"
    return
}

# Define variables
$alertRuleNamePrefix = "VM - Virtual Machine System Up Time - azm "
$Customer = $Parameters.ClNm
$IntSubID = $Parameters.subscriptionId

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

# Define Common Condition for Alert Rules
$dimension = New-AzScheduledQueryRuleDimensionObject -Name "Computer" -Operator "Include" -Value "*"
$condition = New-AzScheduledQueryRuleConditionObject -Dimension $dimension `
    -Query "Perf | where TimeGenerated > ago(30min) | where ObjectName == 'System' | where CounterName == 'Uptime'  or CounterName == 'System Up Time' | summarize MaxSystemUpTime = max(CounterValue) by bin(TimeGenerated, 5m), Computer" `
    -TimeAggregation "Maximum" `
    -MetricMeasureColumn "MaxSystemUpTime" `
    -Operator "LessThan" `
    -Threshold "500"

# Loop Through Virtual Machines and Create Alert Rules
foreach ($vm in $vms) {
    try {
        $vmName = $vm.Name
        $scope = "/subscriptions/$IntSubID/resourceGroups/$($vm.ResourceGroupName)/providers/Microsoft.Compute/virtualMachines/$vmName"
        $alertRuleName = "$alertRuleNamePrefix-$vmName"
        $description = "Client Name:$Customer - Time a virtual machine (VM) has been running without being restarted or experiencing any downtime on VM $vmName"

        New-AzScheduledQueryRule -Name $alertRuleName `
            -ResourceGroupName $Parameters.resourceGroupName `
            -Location $Parameters.location `
            -DisplayName $alertRuleName `
            -Description $description `
            -Scope $scope `
            -Severity 4 `
            -WindowSize ([System.TimeSpan]::FromMinutes(10)) `
            -EvaluationFrequency ([System.TimeSpan]::FromMinutes(5)) `
            -CriterionAllOf $condition

        Write-Host "SUCCESS: Alert rule '$alertRuleName' created successfully." -ForegroundColor Green
    } catch {
        Write-ErrorLog "Failed to create alert rule for VM '$vmName'. Error: $_"
    }
}
