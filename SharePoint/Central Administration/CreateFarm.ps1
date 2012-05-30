# Script based on http://blog.falchionconsulting.com/index.php/2009/10/sharepoint-2010-psconfig-and-powershell/

$farmInstallUserName                   = $Env:COMPUTERNAME + "\Username"
$farmInstallUserPassword               = "PassWord"
$farmPassphrase                        = "PassWord"
$farmDatabaseServer                    = $Env:COMPUTERNAME + "\SQLExpress"
$farmDatabaseName                      = "SP_Farm"
$farmAdministrationContentDatabaseName = "SP_Farm_Admin"
$centraladminPort                      = 15555
$centraladminAuthProvider              = "NTLM"


$user = [Security.Principal.WindowsIdentity]::GetCurrent();
if ((New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator))
{    
    add-pssnapin "Microsoft.SharePoint.PowerShell" -ea "silentlycontinue"
    Start-SPAssignment –Global 
    if (([Microsoft.SharePoint.Administration.SPFarm]::Local) -eq $null) #Only build the farm if we don't currently have a farm created
    {
    	Write-Host "Creating farm on SQL server $farmDatabaseServer..." -ForegroundColor "DarkGreen"
    	
    	# Initialise secure credentials       
    	$farmCredentials = new-object -typename System.Management.Automation.PSCredential -argumentlist $farmInstallUserName,(ConvertTo-SecureString $farmInstallUserPassword –AsPlaintext –Force)
    	$farmPassphraseSecure = (ConvertTo-SecureString $farmPassphrase –AsPlaintext –Force)

    	#Creating new farm     
    	New-SPConfigurationDatabase -DatabaseName $farmDatabaseName -DatabaseServer $farmDatabaseServer -AdministrationContentDatabaseName $farmAdministrationContentDatabaseName -Passphrase $farmPassphraseSecure -FarmCredentials $farmCredentials
    	   
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
    	Install-SPFeature -AllExistingFeatures  

    	#Asume we need a central admin
    	#Provisioning Central Administration  
    	New-SPCentralAdministration -Port $centraladminPort -WindowsAuthProvider $centraladminAuthProvider

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
