if ((New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator))
{
    $xml = [xml](get-content ((Split-Path -Path $MyInvocation.MyCommand.Definition -Parent) + "\SharePointConfig.xml"))
    $webApplicationsXml = $xml.SharePointConfig.Farm.WebApplications

    add-pssnapin "Microsoft.SharePoint.PowerShell" -ea "silentlycontinue"

    foreach ($webApplication in $webApplicationsXml.WebApplication) {
        $webAppUrl = ($webApplication.Config.Protocol + "://" + $webApplication.Config.HostHeader)
        $webApp = Get-SPWebApplication $webAppUrl -ErrorVariable err -ErrorAction SilentlyContinue
        if(-not $err)
        {
            foreach($siteColl in $webApplication.SiteCollections.SiteCollection) {
                $newSite = Get-SPSite $siteColl.Url -ErrorVariable err -ErrorAction SilentlyContinue
                if($err)
                {
                    Write-Host "Site doesn't exists:"$siteColl.Url
                }
                else
                {
                    Write-Host "Deleting Site:"$siteColl.Url
                    Remove-SPSite -Identity $siteColl.Url -Confirm:$False
                }
                $newSite.Dispose()
            }
        } else {
            Write-Host "No Web Application found at url:"$webAppUrl
        }
    }
} else {
	Write-Host "Please run this script as an administrator."
}
