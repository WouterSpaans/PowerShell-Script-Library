if ((New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator))
{
    $xml = [xml](get-content ((Split-Path -Path $MyInvocation.MyCommand.Definition -Parent) + "\SharePointConfig.xml"))
    $webApplicationsXml = $xml.SharePointConfig.Farm.WebApplications

    Import-Module WebAdministration
    add-pssnapin "Microsoft.SharePoint.PowerShell" -ea "silentlycontinue"
    Start-SPAssignment –Global 

    $webApplicationsXml.WebApplication.Config | foreach {
        $webAppUrl = ($_.Protocol + "://" + $_.HostHeader)
        $null = Get-SPWebApplication $webAppUrl -ErrorVariable err -ErrorAction SilentlyContinue
        if($err)
        {
            Write-Host "Creating Web Application:" $_.Name
            
            # Retrieve Application Pool Managed Account or create it
            $ApplicationPoolAccount =  Get-SPManagedAccount $_.ApplicationPool.UserName -ErrorVariable err -ErrorAction SilentlyContinue
            if($err)
            {
            	$ApplicationPoolAccount =  New-SPManagedAccount  (New-Object System.Management.Automation.PSCredential $_.ApplicationPool.UserName, (ConvertTo-SecureString $_.ApplicationPool.PassWord -AsPlainText -force))
            }

            # Create Web Application for MainSite
            $webApp = New-SPWebApplication -Name $_.Name -ApplicationPool $_.ApplicationPool.Name  -ApplicationPoolAccount $ApplicationPoolAccount -DatabaseName $_.DatabaseName -HostHeader $_.HostHeader -Path $_.Path -Port $_.Port

            # Setting caching accounts
            # $webApp = Get-SPWebApplication $webAppUrl
            $webApp.Properties["portalsuperuseraccount"] = $_.Caching.SuperUserName
            $webApp.Properties["portalsuperreaderaccount"] = $_.Caching.SuperReaderName

            # Retrieve Policy Roles
            $policyRolFullRead = $webApp.PolicyRoles | where {$_.Name -eq "Full Read"}
            $policyRolFullControl = $webApp.PolicyRoles | where {$_.Name -eq "Full Control"}
            $webAppPolicySuperUser = $webApp.Policies.Add($_.Caching.SuperUserName, $_.Caching.SuperUserName)
            $webAppPolicySuperUser.PolicyRoleBindings.Add($policyRolFullControl)
            $webAppPolicySuperReader = $webApp.Policies.Add($_.Caching.SuperReaderName, $_.Caching.SuperReaderName)
            $webAppPolicySuperReader.PolicyRoleBindings.Add($policyRolFullRead)
            $webApp.Update()

        } else {
        	Write-Host "WebApplication already exists:" $_.Name
        }     
    }
    Stop-SPAssignment –Global 
} else {
	Write-Host "Please run this script as an administrator."
}
