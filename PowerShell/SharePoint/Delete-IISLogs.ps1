[CmdletBinding()] 
param ( 
[Parameter()] 
[int] 
$OlderThanXDays = 7 
) 

# Get IIS Site Log Files Path 
Import-Module WebAdministration 

## Get the IIS logs folder of all websites. 
$iis_log_folders = @( 
Get-Website | ForEach-Object { 
New-Object psobject -Property $( 
[ordered]@{ 
Site = $_.Name; 
LogPath = $(($_.LogFile.Directory).ToString().Replace('%SystemDrive%', $env:SystemDrive)) + "\W3SVC$($_.id)\" 
} 
) 
} 
) 

## Delete the IIS log files older than $OlderThanXDays 
$thresholdDate = (Get-Date).AddDays(-$OlderThanXDays) 
$iis_log_folders.LogPath | ForEach-Object { 
Get-ChildItem -Path $_ -Filter *.log | ` 
Where-Object { $_.LastWriteTime -lt $thresholdDate } | ` 
Remove-Item -Confirm:$false -Force -Verbose 
}