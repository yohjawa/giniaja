Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
 
Function StartOrStop-SPFarm()
{
    Param(
    [parameter(Mandatory=$true)] $StartOrStopOption
    )
 
    #Get All Servers in the Farm 
    $Farm = Get-SPFarm
    $Servers = $Farm.Servers | Where-Object {$_.Role -ne [Microsoft.SharePoint.Administration.SPServerRole]::Invalid} 
    Write-Host "Total Number of Servers in the Farm: " $Servers.Count 
 
    #List of All SharePoint Services
    $SharePointServices = ('SPSearchHostController','SPTimerV4','SPTraceV4','SPUserCodeV4','SPWriterV4','W3SVC','OSearch16')
 
    #Iterate through each server
    $Servers | ForEach-Object {
     Write-Host "Performing Operation on Server:" $_.Name
        
        #Loop through each service
     foreach($ServiceName in $SharePointServices)
     {
      $ServiceInstance = Get-Service -ComputerName $_.Name -Name $ServiceName -ErrorAction SilentlyContinue
      if($ServiceInstance -ne $null)
      {
                If($StartOrStopOption -eq "Stop")
                {
                    Try 
                    {
                        Write-Host "Attempting to stop service" $ServiceName ".." -ForegroundColor Yellow
                        Stop-Service -InputObject $ServiceInstance
                        Write-Host "Stopped Service" $ServiceName -ForegroundColor Green 
                    }
 
                   catch 
                    {
                       Write-Host "Error Occured on Stopping Service. " $_.Message  -ForegroundColor Red 
                    }
                }
                elseif ($StartOrStopOption -eq "Start")
                {
                    Try 
                    {
                        Write-Host "Attempting to start service" $ServiceName ".." -ForegroundColor Yellow
                        Start-Service -InputObject $ServiceInstance
                        Write-Host "Started Service" $ServiceName -ForegroundColor Green 
                    }
                   catch 
                    {
                     Write-Host "Error Occured on Starting Service. " $_.Message  -ForegroundColor Red 
                    }   
                }
           }
     }
        #Start of Stop IIS
        If($StartOrStopOption -eq "Stop") { iisreset /stop} elseif ($StartOrStopOption -eq "Start") {iisreset /start}
    }
}
 
#Call the function to Stop or Start Services
StartOrStop-SPFarm -StartOrStopOption "Stop"
#StartOrStop-SPFarm -StartOrStopOption "Start"