Add-PSSnapin Microsoft.SharePoint.PowerShell

function CreateList($SPDestSite, $listName, $ListTemplatePath, $AllItemsViewTemplatePath){

    $spWeb = Get-SPWeb -Identity $SPDestSite

    #Get the server template content from "SourceListTemplateXML" file and create Lists and Libraries #according to Template---E.g If ServerTemplate = "100" Then it will create a Custom List and so on.
    $SourceListTemplateXML = [xml](get-content $ListTemplatePath)
    $ListSchema = $SourceListTemplateXML.List
    $ServerTemplate = $ListSchema.ServerTemplate
    $spTemplate = $spWeb.ListTemplates | Where-Object {$_.Type -eq $ServerTemplate}

    #Get all available Lists in Destination site into a List collection.
    $spListCollection = $spWeb.Lists

    #Add/Create the list. If the list already exists then it will not create.
    $spListCollection.Add($listName, $listName, $spTemplate)
    Write-Host $listName
    $path = $spWeb.url.trim()

    $spList = $spWeb.Lists[$listName]

    #Get the content in XML format of both List and its Default View
    $ListTemplateXML = [xml](get-content $ListTemplatePath)
    $AllItemsViewTemplateXML = [xml](get-content $AllItemsViewTemplatePath)

    foreach ($node in $ListTemplateXML.List.Fields.Field) {
        $fieldName = $node.Name
        $ViewLists = $AllItemsViewTemplateXML.View.ViewFields.FieldRef.Name
        if($ViewLists -contains $fieldName) {
            if(($node.Type -ne "Lookup") -and (!($spList.Views[$spList.DefaultView].ViewFields.Exists($node.Name) -eq $true))) {
                try{
                    $spList.Fields.AddFieldAsXml($node.OuterXml, $true,[Microsoft.SharePoint.SPAddFieldOptions]::AddFieldToDefaultView)
                }
                catch{
                    Write-Host "List- $($SPSourceList.Title): Column Name- $($fieldName) Already Exists :("
                }
            }
        }
    }
    $spList.Update()
}

function CreateMissingLookUpColumns($SPDestSite, $listName, $ListTemplatePath, $AllItemsViewTemplatePath) {
    $SPWeb = Get-SPWeb -Identity $SPDestSite
    $SPList = $SPWeb.Lists[$listName]

    $TargettemplateXml = [xml](get-content $ListTemplatePath)
    $AllItemsViewTemplateXML = [xml](get-content $AllItemsViewTemplatePath)

    foreach ($node in $TargettemplateXml.List.Fields.Field) {
        $fieldName = $node.Name
        $ViewLists = $AllItemsViewTemplateXML.View.ViewFields.FieldRef.Name
        if($ViewLists -contains $fieldName) {
            if(($node.Type -eq "Lookup") -and (!($SPList.Views[$SPList.DefaultView].ViewFields.Exists($node.Name) -eq $true))) {
                try{
                    $TargetLookupListName = $node.List
                    $SourceLookupListSchema = $TargettemplateXml.List
                    $SourceLookupListName = $SourceLookupListSchema.Title
                    $TargetlookupColumn = $node.ShowField
                    $SourceColumnLookupName = $node.Name
                    $LookUpRequiredValue = $node.Required
                    $IndexedValue = $node.Indexed
                    $LookupList= $spWeb.Lists[$TargetLookupListName]

                    $fieldXml='<Field Type="Lookup" DisplayName="' + $SourceColumnLookupName + '" Required="' + $LookUpRequiredValue + '" Indexed="'+$IndexedValue+'" ShowField="'+ $TargetlookupColumn +'" StaticName="'+ $SourceColumnLookupName +'" List="' + $LookupList.id + '" Name="' + $SourceColumnLookupName +'"></Field>'

                    $spList.Fields.AddFieldAsXml($fieldXml,$true,[Microsoft.SharePoint.SPAddFieldOptions]::AddFieldToDefaultView)
                }
                catch{
                    Write-Host "Duplicate Column"
                }
            }
        }
    }
    $spList.Update()
}

$lists = @("list1","List2","List3")
$SPDestSite = "http://mysharepointsite.com/sites/test1"

#Create Lists
foreach($list in $lists) {
    $ListTemplatePath = "C:\temp\RRP\$list.xml"
    $AllItemsViewTemplatePath = "C:\temp\RRP\$($list)_View.xml"
    $listName = $list
    CreateList $SPDestSite $listName $ListTemplatePath $AllItemsViewTemplatePath

}

#Create Missing Look Up Columns from created lists
foreach($list in $lists) {
    $ListTemplatePath = "C:\temp\RRP\$list.xml"
    $AllItemsViewTemplatePath = "C:\temp\RRP\$($list)_View.xml"
    $listName = $list
    CreateMissingLookUpColumns $SPDestSite $listName $ListTemplatePath $AllItemsViewTemplatePath
}
