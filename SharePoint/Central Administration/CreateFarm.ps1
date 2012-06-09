# Script based on http://blog.falchionconsulting.com/index.php/2009/10/sharepoint-2010-psconfig-and-powershell/

if ((New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator))
{
    $xml = [xml](get-content ((Split-Path -Path $MyInvocation.MyCommand.Definition -Parent) + "\SharePointConfig.xml"))
    $farmConfigXml = $xml.SharePointConfig.Farm.Config

    add-pssnapin "Microsoft.SharePoint.PowerShell" -ea "silentlycontinue"
    Start-SPAssignment –Global 
    if (([Microsoft.SharePoint.Administration.SPFarm]::Local) -eq $null) #Only build the farm if we don't currently have a farm created
    {
    	Write-Host "Creating SharePoint Farm..." -ForegroundColor "DarkGreen"
    	
    	# Initialise secure credentials   
        $FarmCredentials = new-object -typename System.Management.Automation.PSCredential -argumentlist $farmConfigXml.InstallCredentials.UserName,(ConvertTo-SecureString $farmConfigXml.InstallCredentials.PassWord –AsPlaintext –Force)
        $Passphrase = (ConvertTo-SecureString $farmConfigXml.Passphrase –AsPlaintext –Force)

    	#Creating new farm     
    	New-SPConfigurationDatabase -DatabaseName $farmConfigXml.Database.DatabaseName -DatabaseServer $farmConfigXml.Database.DatabaseServer -AdministrationContentDatabaseName $farmConfigXml.Database.AdministrationContentDatabaseName -Passphrase $Passphrase -FarmCredentials $FarmCredentials
    	   
    	#Verifying farm creation   
    	$spfarm = Get-SPFarm -ErrorAction SilentlyContinue -ErrorVariable err   
    	if ($spfarm -eq $null -or $err) 
    	{         
    		throw "Unable to verify farm creation."   
    	}           
    	
        #ACLing SharePoint Resources 
    	Initialize-SPResourceSecurity     
    	
        #Installing Services       
    	Install-SPService             
        
        #Installing Features      
    	$null = Install-SPFeature -AllExistingFeatures  

        #Asume we need a central admin, Provisioning Central Administration  
    	New-SPCentralAdministration -Port $farmConfigXml.CentralAdmin.Port -WindowsAuthProvider $farmConfigXml.CentralAdmin.AuthProvider

        #Installing Help     
    	Install-SPHelpCollection -All  

        #Installing Application Content  
    	Install-SPApplicationContent

    } else {
    	Write-Host "A farm already exists, skipping creation."
    	Write-Host "To manually remove an existing farm:"
    	Write-Host " - Use the Disconnect-SPConfigurationDatabase command."
    	Write-Host " - Don't forget to remove unused databases afterwards!"
    	Write-Host " - Close and re-open powershell to prevent chaching problems!"
    }
} else {
	Write-Host "Please run this script as an administrator."
}
