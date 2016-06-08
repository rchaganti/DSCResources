# DSCResources #
### Custom DSC resource modules for managing Windows OS configuration (miscellaneous) by [PowerShell Magazine](http://www.powershellmagazine.com "PowerShell Magazine"). ###

----------

This module contains a collection of miscellaneous DSC custom and composite resources for installing VS Code and managing VS Code extensions.

At present, this DSC resource module includes 2 resources.
- [vscodesetup](https://github.com/rchaganti/DSCResources/tree/master/vscode/DSCResources/vscodesetup) is used to add or remove auto administrator logon configuration. This is a composite resource.
- [vscodeextention](https://github.com/rchaganti/DSCResources/tree/master/vscode/DSCResources/vscodeextension) is used to enable or disable Loopback Check registry setting for web servers such as SharePoint Front End servers. This is a composite resource.

Before you can use any of these resources in a configuration script, you must first import the cWindowsOS module or a specific resource from this module.

    Import-DscResource -Module vscode
    Import-DscResource -Module vscode -Name vscodesetup
    Import-DscResource -Name vscodeextension

####Using vscodesetup resource####
The *vscodesetup* resource can be used to install Microsoft Visual Studio Code editor.

![](http://i.imgur.com/rndNDqC.png)

When using this resource, both the *IsSingleInstance* and the *Path* must be specified. The *IsSingleInstance* can only have 'Yes' as a possible valid value. This is done to ensure that this resource gets used only once in the configuration document. The *Path* property takes the path to VS Code setup file. This can be downloaded from [https://go.microsoft.com/fwlink/?LinkID=623230](https://go.microsoft.com/fwlink/?LinkID=623230). 

    VSCodeSetup VSCodeSetup {
        IsSingleInstance = 'yes'
        Path = 'C:\temp\vscodesetup.exe'
        PsDscRunAsCredential = $Credential
        Ensure = 'Present'
    }

The *PsDscRunAsCredential* is important because VS Code install creates the .vscode folder that stores all extensions under the logged-in user's homepath. Without this, this folder gets created at the root of system drive. So, using *PsDscRunAsCredential*, you need to pass the current user credentials.

####Using vscodeextension resource####
The *vscodeextension* can be used to install new VS Code extensions from the market place. At this point in time, this relies on the commandline provided by VS Code but I am exploring other alternatives. Therefore, only VS Code version 1.2.0 onwards is supported for installing VS Code extensions using this resource.

![](http://i.imgur.com/pRREXL5.png)

The only mandatory property in this resource is the *Name* property. You can use this to provide the name of the VS Code extension. Instead of dividing this into two properties like Publisher and Name, I decided to merge both of them into the *Name* property. Therefore the value to this property must be of the form *Publisher.ExtensionName*. You can find this from the marketplace URL for the extension. Using this method, you can be sure that you are always installing the right extension.

    vscodeextension PowerShellExtension {
        Name = 'ms-vscode.PowerShell'
        PsDscRunAsCredential = $Credential
        Ensure = 'Present'
        DependsOn = '[vscodesetup]VSCodeSetup'
    }

Like the *vscodesetup* resource configuration, this resource requires *PsDscRunAsCredential* to ensure the extension gets installed for the current user. Make a note that when using Credentials in DSC configuration scripts, you must encrypt them using certificates. If the certificates cannot be deployed in a test or development environment, you can use the *[PsDscAllowPlainTextPassword](http://www.powershellmagazine.com/2013/09/26/using-the-credential-attribute-of-dsc-file-resource/)* attribute in the DSC configuration data. Remember that this is not recommended in production environment.

Here is an example configuration document that installs VS Code and a couple of extensions.

    $ConfigurationData = @{
    	AllNodes = 
    	@(
    		@{
    			NodeName = '*'
    			PSDscAllowPlainTextPassword = $true
    		},
    		@{
    			NodeName = 'localhost'
    		}
    	)
    }
    
    Configuration VSCodeConfig {
    	param (
    		[pscredential] $Credential
    	)
    	Import-DscResource -ModuleName VSCode
    
    	Node $AllNodes.NodeName {
    		VSCodeSetup VSCodeSetup {
    			IsSingleInstance = 'yes'
    			Path = 'C:\temp\vscodesetup.exe'
    			PsDscRunAsCredential = $Credential
    			Ensure = 'Present'
    		}
    
    		vscodeextension PowerShellExtension {
    			Name = 'ms-vscode.PowerShell'
	    		PsDscRunAsCredential = $Credential
    			Ensure = 'Present'
    			DependsOn = '[vscodesetup]VSCodeSetup'
    		}
    
    		vscodeextension CPPExtension {
    			Name = 'ms-vscode.cpptools'
    			PsDscRunAsCredential = $Credential
    			Ensure = 'Present'
    			DependsOn = '[vscodesetup]VSCodeSetup'
    		}
    	}
    }
    
    VSCodeConfig -ConfigurationData $ConfigurationData -Credential (Get-Credential)

## TODO ##
There are certainly a few things I want to improve in this and also add more resources for customizing VS Code environment. I also want to explore if there is a better way to install extensions instead of using the commandline provided with version 1.2.0.