$user_cache_SuperUser_name   = $Env:COMPUTERNAME + "\Username"
$user_cache_SuperReader_name = $Env:COMPUTERNAME + "\Username"
$user_apppool_Name           = $Env:COMPUTERNAME + "\Username"
$user_apppool_password       = "PassWord"
$intranetWebApp_Name         = "SharePoint - 80"
$AppPoolName                 = "SharePoint - 80"
$intranetWebApp_DatabaseName = "SP_Content"
$intranetWebApp_Port         = "80"
$intranetWebAppPath          = "C:\inetpub\wwwroot\wss\VirtualDirectories\" + $Env:COMPUTERNAME + $intranetWebApp_Port
$intranetWebApp_HostHeader   = $Env:COMPUTERNAME


$user = [Security.Principal.WindowsIdentity]::GetCurrent();
if ((New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator))
{    

    Import-Module WebAdministration
    add-pssnapin "Microsoft.SharePoint.PowerShell" -ea "silentlycontinue"
    Start-SPAssignment –Global 

    $null = Get-SPWebApplication "http://$intranetWebApp_HostHeader" -ErrorVariable err -ErrorAction SilentlyContinue
    if($err)
    {
        Write-Host "Creating Web Application '$intranetWebApp_Name'"

        # Retrieve Application Pool Managed Account or create it
        $ManagedAccount_appPool =  Get-SPManagedAccount $user_apppool_Name -ErrorVariable err -ErrorAction SilentlyContinue
        if($err)
        {
        	$ManagedAccount_appPool =  New-SPManagedAccount  (New-Object System.Management.Automation.PSCredential $user_apppool_Name, (ConvertTo-SecureString $user_apppool_Password -AsPlainText -force))
        }

        # Create Web Application for MainSite
        $null = New-SPWebApplication -Name $intranetWebApp_Name -ApplicationPool $AppPoolName -ApplicationPoolAccount $ManagedAccount_appPool -DatabaseName $intranetWebApp_DatabaseName -HostHeader $intranetWebApp_HostHeader -Path $intranetWebAppPath -Port $intranetWebApp_Port

        # Setting caching accounts
        $intranetWebApp = Get-SPWebApplication "http://$intranetWebApp_HostHeader"
        $intranetWebApp.Properties["portalsuperuseraccount"] = $user_cache_SuperUser_name
        $intranetWebApp.Properties["portalsuperreaderaccount"] = $user_cache_SuperReader_name

        # Retrieve Policy Roles
        $intranetPolicyRolFullRead = $intranetWebApp.PolicyRoles | where {$_.Name -eq "Full Read"}
        $intranetPolicyRolFullControl = $intranetWebApp.PolicyRoles | where {$_.Name -eq "Full Control"}
        $intranetWebAppPolicySuperUser = $intranetWebApp.Policies.Add($user_cache_SuperUser_name, $user_cache_SuperUser_name)
        $intranetWebAppPolicySuperUser.PolicyRoleBindings.Add($intranetPolicyRolFullControl)
        $intranetWebAppPolicySuperReader = $intranetWebApp.Policies.Add($user_cache_SuperReader_name, $user_cache_SuperReader_name)
        $intranetWebAppPolicySuperReader.PolicyRoleBindings.Add($intranetPolicyRolFullRead)
        $intranetWebApp.Update()
    } else {
    	Write-Host "WebApplication already exists."
    }
    Stop-SPAssignment –Global 
} else {
	Write-Host "Please run this script as an administrator."
}
