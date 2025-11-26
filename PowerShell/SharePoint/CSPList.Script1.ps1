Add-PSSnapin Microsoft.SharePoint.PowerShell

function SetLookupField($SPSourceWeb, $SPSourceList, $ListTemplatePath, $AllItemsViewTemplatePath){
    $ListTemplateXML = [xml](get-content $ListTemplatePath)
    $AllItemsViewTemplateXML = [xml](get-content $AllItemsViewTemplatePath)
    $ViewFieldNames = $AllItemsViewTemplateXML.View.ViewFields.FieldRef.Name
    foreach ($node in $ListTemplateXML.List.Fields.Field) {
        $fieldName = $node.Name
        if($ViewFieldNames -contains $fieldName) {
            if($node.Type -eq "Lookup") {
                try{
                    $TargetLookupListId = $node.List
                    $TargetLookupListName = $SPSourceWeb.lists[[GUID]($TargetLookupListId)]
                    $node.List = $TargetLookupListName.Title
                    $ListTemplateXML.Save($ListTemplatePath)
                }
                catch{
                    Write-Host "List- $($SPSourceList.Title): Column Name- $($fieldName)  Already Exists :("
                }
            }
        }
    } 
}

#Write all the list names which you want to migrate from source site to destination site.
$lists = @("List1","List2","List3")
$SPSourceWeb = Get-SPWeb "http://mysharepointsite.com/sites/test1"

foreach($list in $lists) {
    $SPSourceList = $SPSourceWeb.Lists[$list]
    
    #Extract the XML Schema of the current list.
    $SPSourceListSchema = $SPSourceList.SchemaXml

    #Save the XML Schema of the current list in Local Drive.
    Write-Output $SPSourceListSchema > C:\temp\RRP\$list.xml
    $ListTemplatePath = "C:\temp\RRP\$list.xml"

    #Get the Default view of the current list
    $SPSourceListDefaultView = $SPSourceList.DefaultView

    #Extract the XML Schema of current list Default view
    #Condition: If you want to create only those columns which are present in Default view
    $SPSourceListViewSchema = $SPSourceList.Views[$SPSourceListDefaultView].SchemaXml

    #Save the XML Schema of the current list Default view in Local Drive.
    Write-Output $SPSourceListViewSchema > C:\temp\RRP\$($list)_View.xml
    $AllItemsViewTemplatePath = "C:\temp\RRP\$($list)_View.xml"

    #Basic purpose of calling below method is to update the field in list XML which is of Lookup Type.
    SetLookupField $SPSourceWeb $SPSourceList $ListTemplatePath $AllItemsViewTemplatePath

}