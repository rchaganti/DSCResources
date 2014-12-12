# DSCResources #
### Custom DSC resource modules by [PowerShell Magazine](http://www.powershellmagazine.com "PowerShell Magazine"). ###

----------
Custom DSC resource modules in this repository are packaged as different categories based on the functionality.
- WMI Permanent Events Module ([cWMIPermanentEvents](https://github.com/rchaganti/DSCResources/tree/master/cWMIPermanentEvents))
	- [cWMIEventFilter](https://github.com/rchaganti/DSCResources/tree/master/cWMIPermanentEvents/DSCResources/cWMIEventFilter) is used to create event filter instances for a given event query and event namespace. 
	- [cWMIEventBinding](https://github.com/rchaganti/DSCResources/tree/master/cWMIPermanentEvents/DSCResources/cWMIEventBinding) is used to create binding between an event filter instance and an event consumer instance.
	- [cWMIEventLogConsumer](https://github.com/rchaganti/DSCResources/tree/master/cWMIPermanentEvents/DSCResources/cWMIEventLogConsumer) is used to create an instance of WMI Event Log consumer that writes to application log in response to an event.
	- [cWMILogFileConsumer](https://github.com/rchaganti/DSCResources/tree/master/cWMIPermanentEvents/DSCResources/cWMILogFileConsumer) is used to create an instance of WMI Log File that writes to a text log file in response to an event.
	- [cWMIActiveScriptConsumer](https://github.com/rchaganti/DSCResources/tree/master/cWMIPermanentEvents/DSCResources/cWMIActiveScriptConsumer) is used to create an instance of WMI Active Script Consumer that executes a specified VBScript file and VBScript text fragment in response to an event.
	- [cWMICommandLineConsumer](https://github.com/rchaganti/DSCResources/tree/master/cWMIPermanentEvents/DSCResources/cWMICommandLineConsumer) is used to create an instance of WMI CommandLine Consumer that executes a native application or a batch script in response to an event.
	- [cWMISMTPConsumer](https://github.com/rchaganti/DSCResources/tree/master/cWMIPermanentEvents/DSCResources/cWMISMTPConsumer) is used to create an instance of WMI SMTP Consumer that sends an email in response to an event.
- Windows OS Miscellaneous Module ([cWindowsOS](https://github.com/rchaganti/DSCResources/tree/master/cWindowsOS))
	- [cHostsFile](https://github.com/rchaganti/DSCResources/tree/master/cWindowsOS/DSCResources/cHostsFile) is used to manage Hosts file entries.
	- [cAutoAdminLogon](https://github.com/rchaganti/DSCResources/tree/master/cWindowsOS/DSCResources/cAutoAdminLogon) is used to add or remove auto administrator logon configuration. This is a composite resource.
	- [cLoopBackCheck](https://github.com/rchaganti/DSCResources/tree/master/cWindowsOS/DSCResources/cLoopBackCheck) is used to enable or disable Loopback Check registry setting for web servers such as SharePoint Front End servers. This is a composite resource.
	- c[DiskImage](https://github.com/rchaganti/DSCResources/tree/master/cWindowsOS/DSCResources/cDiskImage) is used to mount or dismount ISO images.
- Microsoft Monitoring Agent ([cMMAgent](https://github.com/rchaganti/DSCResources/tree/master/cMMAgent))
	- [cMMAgentInstall](https://github.com/rchaganti/DSCResources/tree/master/cMMAgent/DSCResources/cMMAgentInstall) is used to install Microsoft Monitoring Agent.
	- [cMMAgentProxyName](https://github.com/rchaganti/DSCResources/tree/master/cMMAgent/DSCResources/cMMAgentProxyName) is used to add or remove the proxy URL for the Microsoft Monitoring Agent configuration.
	- [cMMAgentProxyCredential](https://github.com/rchaganti/DSCResources/tree/master/cMMAgent/DSCResources/cMMAgentProxyCredential) is used to add, modify, or remove the credentials that need to be used to authenticate to a proxy configured using cMMAgentProxyName resource.
	- [cMMAgentOpInsights](https://github.com/rchaganti/DSCResources/tree/master/cMMAgent/DSCResources/cMMAgentOpInsights) is used to enable or disable Azure Operational Insights within the Microsoft Monitoring Agent. This can also be used to update the WorkspaceID and WorkspaceKey for connecting to Azure Operational Insights.
	- [cMMAgentAD](https://github.com/rchaganti/DSCResources/tree/master/cMMAgent/DSCResources/cMMAgentAD) is used to enable or disable Active Directory integration for the Microsoft Management Agent. By enabling AD integration, you can assign agent-managed computers to management groups.
	- [cMMAgentManagementGroups](https://github.com/rchaganti/DSCResources/tree/master/cMMAgent/DSCResources/cMMAgentManagementGroups) DSC resource can be used to add or remove management groups. You can use this resource to update the action account credentials for the management agent service.

These modules are available on [PowerShellGallery.com](https://www.powershellgallery.com). If you are using Windows PowerShell 5.0 Preview, you can install these modules using PowerShellGet module.

    Install-Module -Name cMMAgent
    Install-Module -Name cWindowsOS
    Install-Module -Name cWMIPermanentEvents