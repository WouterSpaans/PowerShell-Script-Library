if ((New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator))
{
    $xml = [xml](get-content ((Split-Path -Path $MyInvocation.MyCommand.Definition -Parent) + "\SharePointConfig.xml"))
    $SharePointFoundationSearchXml = $xml.SharePointConfig.Farm.Services.SharePointFoundationSearch

    add-pssnapin "Microsoft.SharePoint.PowerShell" -ea "silentlycontinue"
    
    #Get the Search service instance, when not online start it up before returning
    $SearchServiceInstance = Get-SPSearchServiceInstance -local 
    if($SearchServiceInstance.Status -ne "Online")
    {
    	Write-Host "Search Service Instance not started. Starting...." -ForegroundColor "DarkGreen"
    	Start-SPServiceInstance -Identity $SearchServiceInstance
    }    	
    
    
}