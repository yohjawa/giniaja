Add-PSSnapin microsoft.sharepoint.powershell -ErrorAction SilentlyContinue

# get workflows status
$web = Get-SPWeb -Identity "http://mysharepointsite.com/sites/test1"
$list = $web.Lists["List Name"]
$wfm = New-Object Microsoft.SharePoint.WorkflowServices.WorkflowServicesManager($web)
$sub = $wfm.GetWorkflowSubscriptionService()
$wf = $sub.EnumerateSubscriptionsByList($list.ID)
$wfis = $wfm.GetWorkflowInstanceService()

foreach ($item in $list.Items) {
    $workflowInstances = $wfis.EnumerateInstancesForListItem($list.ID, $item.ID)
    foreach ($wf in $workflowInstances) {
        $wfID = $wf.ID
        $wfStatus = $wf.Status
        $wfListItem = $item.Name
        Write-Host "Workflow Title: $wfID Status: $wfStatus ListItem: $wfListItem"
    }
}

## actually stop the running workflow
$siteURL = "http://mysharepointsite.com/sites/test1"
$listName = "List Name"

$spWeb = Get-SPWeb $siteURL
$spList = $spWeb.Lists[$listName]
$spListItems = $spList.Items

# Get the Workflow Manager object and then the instance of the Manager
$wfMgr = New-object Microsoft.SharePoint.WorkflowServices.WorkflowServicesManager($spWeb)
$wfInstanceSvc = $wfMgr.GetWorkflowInstanceService()

foreach ($spListItem in $spListItems) {
    # Get a list of workflow instances running for the item in the list
    $wfInstances = $wfInstanceSvc.EnumerateInstancesForListItem($spList.ID, $spListItem.ID)
    foreach ($wfInstance in $wfInstances) {
        # Check if the instance is suspended. If so, terminate it.
        if ($wfInstance.Status -eq "Suspended") {
            Write-Host "Terminating instances for list item: $($spListItem.ID)"
            #$wfInstanceSvc.TerminateWorkflow($wfInstance)
        }
    }
}
