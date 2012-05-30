add-pssnapin "Microsoft.SharePoint.PowerShell" -ea "silentlycontinue"

$intranetWebAppFullURL                    = "http://" + $Env:COMPUTERNAME
$intranetWebApp_SiteCollectionOwner       = $Env:COMPUTERNAME + "\Username"
$intranetWebApp_SiteCollectionTitle       = "SharePoint Test Site"
$intranetWebApp_SiteCollectionTemplate    = "STS#1" # STS#0 = Team Site, STS#1 = Blank Site
$intranetWebApp_SiteCollectionDescription = "SharePoint Test Site Description"
$intranetWebApp_SiteCollectionLanguage    = 1033 # 1043 = Dutch

Write-Host "CreateSite.ps1" -BackgroundColor "Black" -ForegroundColor "White"
Write-Host "  Creating Site: $intranetWebAppFullURL" -ForegroundColor "Gray"
$newSite = New-SPSite $intranetWebAppFullURL -OwnerAlias $intranetWebApp_SiteCollectionOwner -name $intranetWebApp_SiteCollectionTitle -Template $intranetWebApp_SiteCollectionTemplate -Description $intranetWebApp_SiteCollectionDescription -Language $intranetWebApp_SiteCollectionLanguage
$newSite.Dispose()


