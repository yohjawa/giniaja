Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

# Output file path
$outputFile = "C:\Temp\SharePoint_LastAccess_Report_$(Get-Date -Format 'yyyyMMdd').csv"
$reportData = @()

# Function to get last access information for a site
function Get-SPLastAccessData {
    param (
        [Microsoft.SharePoint.SPSite]$site
    )
    
    $result = @{
        WebApplication = $site.WebApplication.Name
        SiteUrl = $site.Url
        LastContentModifiedDate = $site.LastContentModifiedDate
        LastItemModifiedDate = $site.RootWeb.LastItemModifiedDate
    }
    
    try {
        # Try to get analytics data if available
        $analytics = New-Object Microsoft.Office.Server.Analytics.AnalyticsUsageEntry($site)
        $result["LastProcessingTime"] = $analytics.LastProcessingTime
        $result["DaysSinceLastProcessing"] = ((Get-Date) - $analytics.LastProcessingTime).Days
    }
    catch {
        $result["LastProcessingTime"] = "Not Available"
        $result["DaysSinceLastProcessing"] = "N/A"
    }
    
    return New-Object PSObject -Property $result
}

Write-Host "Processing all web applications in the farm..." -ForegroundColor Cyan

# Get all web applications in the farm
$webApplications = Get-SPWebApplication

foreach ($webApp in $webApplications) {
    Write-Host "Processing Web Application: $($webApp.Name)" -ForegroundColor Yellow
    
    # Get all site collections in this web app
    $sites = $webApp.Sites
    
    foreach ($site in $sites) {
        try {
            Write-Host "  Processing Site: $($site.Url)" -ForegroundColor Green
            $siteData = Get-SPLastAccessData -site $site
            $reportData += $siteData
            
            # Display progress
            Write-Host "    Last Content Modified: $($siteData.LastContentModifiedDate)"
            if ($siteData.LastProcessingTime -ne "Not Available") {
                Write-Host "    Last Analytics Processing: $($siteData.LastProcessingTime) ($($siteData.DaysSinceLastProcessing) days ago)"
            }
        }
        catch {
            Write-Host "    Error processing site $($site.Url): $_" -ForegroundColor Red
        }
        finally {
            $site.Dispose()
        }
    }
}

# Export results to CSV
$reportData | Select-Object WebApplication, SiteUrl, LastContentModifiedDate, LastItemModifiedDate, LastProcessingTime, DaysSinceLastProcessing | 
    Export-Csv -Path $outputFile -NoTypeInformation -Force

Write-Host "Report generated at: $outputFile" -ForegroundColor Cyan