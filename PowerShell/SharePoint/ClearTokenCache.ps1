# -------------------------------
# CONFIGURATION
# -------------------------------
# Replace these values
$webUrl = "http://your-site-url"         # Your SharePoint site URL
$userLogin = "DOMAIN\\username"          # AD user to check
$groupName = "DOMAIN\\YourGroupName"     # AD group name used in SharePoint
# -------------------------------

Write-Host "=== Clearing SharePoint Token Cache ==="

# Stop Timer Service
Stop-Service SPTimerV4 -Force
Start-Sleep -Seconds 5

# Delete token cache files (may vary per farm - adjust if needed)
$configCachePath = "$env:ALLUSERSPROFILE\Microsoft\SharePoint\Config"

if (Test-Path $configCachePath) {
    Get-ChildItem -Path $configCachePath -Recurse -Include *.xml | Remove-Item -Force -ErrorAction SilentlyContinue
    Write-Host "🧹 Deleted SharePoint config XML cache files."
} else {
    Write-Warning "Config path not found: $configCachePath"
}

# Start Timer Service again
Start-Service SPTimerV4
Write-Host "✅ SharePoint Timer Service restarted."

# Recycle Application Pools
Write-Host "🔁 Recycling all SharePoint app pools..."
Get-SPServiceApplicationPool | ForEach-Object { $_.Recycle() }

# Optional: IISRESET
# Write-Host "🔁 Restarting IIS..."
# iisreset

Start-Sleep -Seconds 10

# -------------------------------
# Group Membership Resolution Test
# -------------------------------
Write-Host "`n=== Verifying Group Membership in SharePoint ==="

# Ensure user is resolved
$user = Get-SPUser -Web $webUrl -Identity $userLogin -ErrorAction SilentlyContinue
