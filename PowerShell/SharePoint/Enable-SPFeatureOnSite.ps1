$features = @(
"d33c5b4b-c6bc-45cd-ab7a-5262848e7a3d"
,"1e002c12-bc9b-48fd-b1f9-a03cd00cb811"
,"0d814a91-156d-43a7-9036-3281732b2f39"
,"d6fe88a1-8659-44ad-ad0e-f34d775763a1"
,"3fda91fb-c062-4442-b474-1ecba26d325f"
,"4219020b-59bf-4354-b16a-bdac1846c71a"
)
$webApp = "http://mysharepointsite.com"
foreach($ft in $features) {
	Disable-SPFeature -Identity $ft -Url $webApp
}

foreach($ft in $features) {
	Enable-SPFeature -Identity $ft -Url $webApp
}