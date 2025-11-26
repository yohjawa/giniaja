#Add SharePoint Snapin
if ( (Get-PSSnapin -Name "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null ) {
        Add-PSSnapin "Microsoft.SharePoint.PowerShell"
}
 
# Configuration Variables
$WebApplicationURL = "http://mysharepointsite.com/"
$ReportOutput = "C:\temp\SiteCollectionsAndSites.html"
 
#Get all Site Collections from the webapplication
$SitesColl= Get-SPWebApplication $WebApplicationURL | Get-SPSite -Limit All
 
$HTMLTemplate=@"
<html>
<head>
<!-- Sal - Javascript Function to apply formatting -->
<script type="text/javascript">
function altRows(id){
 if(document.getElementsByTagName){     
  var table = document.getElementById(id);  
  var rows = table.getElementsByTagName("tr");     
  for(i = 0; i < rows.length; i++){          
   if(i % 2 == 0){
    rows[i].className = "evenrowcolor";
   }else{
    rows[i].className = "oddrowcolor";
   }      
  }
 }
}
window.onload=function(){
 altRows('alternatecolor');
}
</script>
   
<!-- CSS Styles for Table TH, TR and TD -->
<style type="text/css">
body{ font-family: Calibri; height: 12pt; }
  
table.altrowstable {
 border-collapse: collapse; font-family: verdana,arial,sans-serif;
 font-size:11px; color:#333333; border-width: 1px; border-color: #a9c6c9;
 border: b1a0c7 0.5pt solid; /*Sal Table format */  
}
table.altrowstable th {
 border-width: 1px; padding: 5px; background-color:#8064a2;
 border: #b1a0c7 0.5pt solid; font-family: Calibri; height: 15pt; 
 color: white;  font-size: 11pt;  font-weight: 700;  text-decoration: none;
}
table.altrowstable td {
 border: #b1a0c7 0.5pt solid; font-family: Calibri; height: 15pt; color: black; 
 font-size: 11pt; font-weight: 400; text-decoration: none; 
}
.oddrowcolor{ background-color: #e4dfec; }
.evenrowcolor{ background-color:#FFFFFF; }
</style>
</head>
<body>
"@
 
 #Add the HTML File with CSS into the Output report
$Content = $HTMLTemplate > $ReportOutput
     
"<h2> Site Collections & Subsites Report </h2>" >> $ReportOutput 
#Table of Contents
"<h3> Summary of Site Collections</h3> <table class='altrowstable' id='alternatecolor' cellpadding='5px'><tr><th>Site Collection Name </th><th> URL </th><th> No.Of Subsites </th></tr>" >> $ReportOutput
 
#Loop throuh each site collection 
foreach($Site in $SitesColl) 
{
    "<tr> <td> <a href='#$($Site.Rootweb.Title.ToLower())'>$($Site.Rootweb.Title)</a> </td><td> $($Site.Rootweb.URL)</td> <td> $($Site.AllWebs.Count) </td></tr>" >> $ReportOutput
}
"</table><br/><hr>" >> $ReportOutput
 
#Get All sub Sites
foreach($Site in $SitesColl) 
{
    "<h4> Subsites of Site Collection: <a name='$($Site.RootWeb.Title.ToLower())' href='$($Site.RootWeb.URL)' target='_blank'>$($Site.RootWeb.Title)</a> </h4> ">> $ReportOutput
    "<table class='altrowstable' id='alternatecolor' cellpadding='5px'><tr><th>Site Name </th><th> Site URL </th><th> Last Modified </th></tr>" >> $ReportOutput
    foreach($Web in $Site.AllWebs)
    { 
      "<tr> <td>$($web.Title)</td><td> <a href='$($web.URL)' target='_blank'>$($web.URL)</a></td> <td> $($web.lastitemmodifieddate) </td></tr>" >> $ReportOutput
    }
     
    "</table></br> " >>$ReportOutput
} #Web
"</body></html>" >>$ReportOutput
 
Write-host "`n Site Collections & Subsites Report generated successfully at "$ReportOutput