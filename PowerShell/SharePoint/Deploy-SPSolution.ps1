# Download WSP Solution as backup
#$wsps = Import-Csv -Path "D:\Sources\WSPS\wsplist.csv"
#$wsps = Get-ChildItem -Path "D:\Sources\WSPS\deploy"
$backupPath = "D:\WSP\Backup\" + (Get-Date).ToString("ddMMyyyy") + "\"
$newPath = "D:\WSP\New\"
$wsps = Get-ChildItem -Path $newPath
$farm = Get-SPFarm 
$webApp = "http://mysharepointsite.com"
## download existing solutions
ForEach ($wsp in $wsps.Name) {
    if (!(Test-Path $backupPath)) { New-Item -ItemType Directory -Path $backupPath -Force | Out-Null }

    $wspBackupFile = $backupPath + $wsp
    $file = $farm.Solutions.Item($wsp).SolutionFile
    $file.SaveAs($wspBackupFile)
}

# Remove WSP Solution
ForEach ($wsp in $wsps.Name) {
    #Uninstall-SPSolution -Identity $wsp
    #Start-Sleep -Seconds 1
    Remove-SPSolution -Identity $wsp
}

# upload new sp solution
ForEach ($wsp in $wsps.Name) {
    $wspNewFile = $newPath + $wsp
    Add-SPSolution $wspNewFile
}

#deploy new sp solution
ForEach ($wsp in $wsps.Name) {
    Install-SPSolution -Identity $wsp -WebApplication $webApp -GACDeployment -FullTrustBinDeployment
}

#Install-SPSolution -Identity "TEPI.DisTrack.SP.wsp " -WebApplication "http://mysharepointsite.com" -GACDeployment -FullTrustBinDeployment