function Remove-SPFeatureFromContentDB ($ContentDb, $FeatureId, [switch]$ReportOnly) {
    $db = Get-SPDatabase | where { $_.Name -eq $ContentDb }
    [bool]$report = $false
    if ($ReportOnly) { $report = $true }

    $db.Sites | ForEach-Object {
        Remove-SPFeature -obj $_ -objName "site collection" -featId $FeatureId -report $report
        $_ | Get-SPWeb -Limit all | ForEach-Object {
            Remove-SPFeature -obj $_ -objName "site" -featId $FeatureId -report $report
        }
    }
}

function Remove-SPFeature ($obj, $objName, $featId, [bool]$report) {
    $feature = $obj.Features[$featId]
    if ($feature -ne $null) {
        if ($report) {
            Write-Host "Feature found in $objName: $($obj.Url)" -ForegroundColor Red
        } else {
            try {
                $obj.Features.Remove($feature.DefinitionId, $true)
                Write-Host "Feature successfully removed from $objName: $($obj.Url)" -ForegroundColor Green
            } catch {
                Write-Host "Error removing feature: $_"
            }
        }
    } else {
        Write-Host "Feature ID not found in $objName: $($obj.Url)"
    }
}

# Example usage
$contentDB = "ContentDB"
$featureId = "a786d5e1-8e28-48c7-90db-5c203e7e2545"
Remove-SPFeatureFromContentDB -ContentDB $contentDB -FeatureId $featureId
