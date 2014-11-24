# DSCResources #
### Custom DSC resource module for Microsoft Monitoring Agent by [PowerShell Magazine](http://www.powershellmagazine.com "PowerShell Magazine"). ###

----------

Microsoft Monitoring Agent (MMA) is used to connect target systems to System Center Operations Manager or directly to Azure Operational Insights. This DSC resource module intends to build custom resources for installing and configuring MMA on target systems.

At present, there is just one DSC resource available. 


- [cMMAgentInstall](https://github.com/rchaganti/DSCResources/tree/master/cMMAgent/DSCResources/cMMAgentInstall) is used to install Microsoft Monitoring Agent for Azure Operational Insights.

####Using cMMAgentInstall resource####
The cMMAgentInstall is a composite DSC resource. This can be used to install MMAgent in an unattended manner. Behind the scenes, this resource uses the Package DSC resource.

![](http://i.imgur.com/tkrhB01.png)

The *Path* property is used to specify a local folder path where MMAgent installer is stored. This can also be the HTTP location for downloading an installer. For example, the following function can be used to get the redirected URL from fwlink on Microsoft site.

    Function Get-TrueURL {   
       Param (
          [parameter(Mandatory)]
          $Url
       )
       $req = [System.Net.WebRequest]::Create($url)
       $req.AllowAutoRedirect=$false
       $req.Method="GET"
    
       $resp=$req.GetResponse()
       if ($resp.StatusCode -eq "Found") {
          return $resp.GetResponseHeader("Location")
       }   
       else {
          return $resp.responseURI
       }
    }

The fwlink to download MMAgent installer is http://go.microsoft.com/fwlink/?LinkID=517476.

    $TrueUrl = Get-TrueUrl -Url 'http://go.microsoft.com/fwlink/?LinkID=517476'

Now, this redirected URL can be given as value can be given as the value of *Path* property. The Package resource downloads the installer before it attempts to install it on the target system.

The *WorkspaceID* and the *WorkspaceKey* can be retrieved from the [Azure Operational Insights preview portal](https://preview.opinsights.azure.com) by navigating to Servers & Usage -> Configure.

![](http://i.imgur.com/k2Q7q9j.png)

Here is a configuration script that uses the cMMAgentInstall composite resource.

    Configuration MMASetup {
       Import-DscResource -Module cMMAgent -Name cMMAgentInstall
       cMMAgentInstall MMASetup {
          Path = 'C:\OpInsights\MMASetup-AMD64.exe'
          Ensure = 'Present'
          WorkspaceID = 'your-Workspace-Id'
          WorkspaceKey = 'Your-Workspace-Key'
       }
    }
    
    MMASetup