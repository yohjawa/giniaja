Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

# === Parameters ===
$serviceAppName = "SSRS Service Application"
$appPoolName = "SharePoint Web Services Default"
$databaseServer = "YourSQLServerInstance"
$databaseName = "SSRS_ServiceApp_DB"

# === Cleanup Old Service App and Proxy ===
Write-Host "Removing existing SSRS Service Application and Proxy (if any)..." -ForegroundColor Yellow
$existingApp = Get-SPServiceApplication | Where-Object { $_.Name -eq $serviceAppName }
if ($existingApp) {
    Remove-SPServiceApplication $existingApp -RemoveData -Confirm:$false
    Write-Host "Removed existing service application: $serviceAppName" -ForegroundColor Green
}

$existingProxy = Get-SPServiceApplicationProxy | Where-Object { $_.Name -eq "$serviceAppName Proxy" }
if ($existingProxy) {
    Remove-SPServiceApplicationProxy $existingProxy -Confirm:$false
    Write-Host "Removed existing service application proxy" -ForegroundColor Green
}

# === Get Application Pool ===
$appPool = Get-SPServiceApplicationPool $appPoolName
if (-not $appPool) {
    Write-Host "Application Pool '$appPoolName' not found. Creating new one..." -ForegroundColor Yellow
    $appPool = New-SPServiceApplicationPool -Name $appPoolName -Account (Get-SPManagedAccount)
}

# === Create SSRS Service Application ===
Write-Host "Creating SSRS Service Application..." -ForegroundColor Yellow
$ssrsServiceApp = New-SPRSServiceApplication -Name $serviceAppName `
    -ApplicationPool $appPool `
    -DatabaseServer $databaseServer `
    -DatabaseName $databaseName

# === Create SSRS Service Application Proxy ===
Write-Host "Creating SSRS Service Application Proxy..." -ForegroundColor Yellow
$ssrsServiceAppProxy = New-SPRSServiceApplicationProxy -Name "$serviceAppName Proxy" `
    -ServiceApplication $ssrsServiceApp `
    -DefaultProxyGroup

Write-Host "SSRS Service Application rebuild completed successfully!" -ForegroundColor Green
