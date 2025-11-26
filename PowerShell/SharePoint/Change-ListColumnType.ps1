Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
 
#Get the Web where Lists Live
$web= Get-SPWeb "http:/mysharepointsite.com/"

#Define Array to hold Lists Names to Scan
$ListNames =  ("E-ARCHIVES")
 
#Column to Change
$ColumnName ="VBOX Description"
 
 #Iterate through provided Lists 
foreach($ListName in $ListNames)
{
    #Get the List
    $list = $web.Lists.TryGetList($ListName) 
    if( $list -ne $null)
     {
        #Check if the list has our target column to change
        if($list.fields.ContainsField($ColumnName))
        {
           #Get the Column to Change
           $column = $List.Fields[$ColumnName]
    
           #Change the Column type to "Multiple Lines of Text"
           $column.Type
           #$column.Type = [Microsoft.SharePoint.SPFieldType]::Note
           #$column.Update()
           #Write-Host "Field type updated on: $($List.Title)"
        }
    }
}
 
$web.Dispose()