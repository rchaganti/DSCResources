# DSCResources #
### Custom DSC resource module for Microsoft Azure Recovery Services Agent by [PowerShell Magazine](http://www.powershellmagazine.com "PowerShell Magazine"). ###

----------

[Microsoft Azure Recovery Services Agent](http://azure.microsoft.com/en-in/documentation/articles/backup-configure-vault/) (MARS) is used to connect target systems to Azure Backup or Recovery Services vault. This [DSC resource module](https://github.com/rchaganti/DSCResources/tree/master/cMicrosoftAzureRecoveryServices) intends to build custom resources for installing and configuring MARS Agent on target systems.

- [cMARSAgentInstall](https://github.com/rchaganti/DSCResources/tree/master/cMicrosoftAzureRecoveryServices/DSCResources/cMARSAgentInstall) is used to install Microsoft Azure Recovery Services Agent. This is a composite resource that uses Package resource behind the scenes.
- [cMARSProxy](https://github.com/rchaganti/DSCResources/tree/master/cMicrosoftAzureRecoveryServices/DSCResources/cMARSProxy) is used to configure the proxy settings for the MARS agent to connect to the Azure Backup Vault.
- [cMARSRegistration](https://github.com/rchaganti/DSCResources/tree/master/cMicrosoftAzureRecoveryServices/DSCResources/cMARSRegistration) DSC resource should be used to register a target system with the Azure backup vault.
- [cMARSEncryptionPhrase](https://github.com/rchaganti/DSCResources/tree/master/cMicrosoftAzureRecoveryServices/DSCResources/cMARSEncryptionPhrase) is used to configure the encryption settings for the MARS agent service.

At present, this resource module contains four DSC resources that are the fundamental building blocks for using MARS Agent.

####Using cMARSAgentInstall resource####
The [cMARSgentInstall](https://github.com/rchaganti/DSCResources/tree/master/cMicrosoftAzureRecoveryServices/DSCResources/cMARSAgentInstall) is a composite DSC resource. This can be used to install MARS Agent in an unattended manner. Behind the scenes, this resource uses the Package DSC resource.

![](http://i.imgur.com/DsqnEob.png)

The *SetupPath* property is used to specify a local folder path where MARS Agent installer is stored. This can also be the HTTP location for downloading an installer. For example, the following function can be used to get the redirected URL from fwlink on Microsoft site.

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

The fwlink to download MARS Agent installer is [https://go.microsoft.com/fwLink/?LinkID=288905&clcid=0x409](https://go.microsoft.com/fwLink/?LinkID=288905&clcid=0x409).

    $TrueUrl = Get-TrueUrl -Url 'https://go.microsoft.com/fwLink/?LinkID=288905&clcid=0x409'

Now, this redirected URL can be given as value can be given as the value of *Path* property. The Package resource downloads the installer before it attempts to install it on the target system.

Here is a configuration script that uses the cMMAgentInstall composite resource.

    cMARSAgentInstall AgentSetup {
    	SetupPath = 'C:\AzureBackup\MARSAgentInstaller.exe'
    	EnableWindowsUpdate = $true
    	Ensure = 'Present'
    }

The *EnableWindowsUpdate* property when specified uses Windows Update, after the install, to check if there are any updates to the agent software. This property is not mandatory.

Once you have installed the MARS agent, you can register the target system with the backup vault. But, before that, if your target system is behind a proxy server, you need to specify the proxy server and proxy port. This can be done using the [cMARSProxy](https://github.com/rchaganti/DSCResources/tree/master/cMicrosoftAzureRecoveryServices/DSCResources/cMARSProxy) DSC resource. 

####Using cMARSProxy resource####
The [cMARSProxy](https://github.com/rchaganti/DSCResources/tree/master/cMicrosoftAzureRecoveryServices/DSCResources/cMARSProxy) resource can be used to add or remove proxy settings for the Microsoft Azure Recovery Services Agent.

![](http://i.imgur.com/GlIFg7B.png)

The only property that is mandatory is the *ProxyServer*. For this, you need to specify a proxy URL (either HTTP or HTTPS). The following configuration script demonstrates this usage.

    cMARSProxy MARSProxy {
        ProxyServer = 'https://myProxy'
        Ensure = 'Present'
    }

DO NOT add the proxy port as a part of the URL. Instead, use the *ProxyPort* property. 

    cMARSProxy MARSProxy {
        ProxyServer = 'https://myProxy'
        ProxyPort = 1010
        Ensure = 'Present'
    }

Optionally, if your proxy server requires authentication, you can specify that using the *ProxyCredential* property. This is a *PSCredential* type property and therefore you need to use certificates to encrypt the credentials within the configuration. In case you don't have the certificates for your development or test environment, you can pass the clear-text credentials.

    $ProxyCredential = Get-Credential
    
    $ConfigData = @{
       AllNodes = @(
          @{ NodeName = '*'; PsDscAllowPlainTextPassword = $true },
          @{ NodeName = 'MARSDemo' }
       )
    }
    
    Configuration MARSAgentConfiguration {
       Import-DscResource -ModuleName cMicrosoftAzureRecoveryServices
       Node $AllNodes.NodeName {
          cMARSProxy MARSProxy {
             ProxyServer = 'https://myProxy'
             ProxyPort = 1010
             ProxyCredential = $ProxyCredential
             Ensure = 'Present'
          }
       }
    }

Once you set the proxy credentials, if you need to change the password alone within the credentials, you can use the *Force* property to force that change. When using *Force* property.

    $ProxyCredential = Get-Credential
    
    $ConfigData = @{
       AllNodes = @(
          @{ NodeName = '*'; PsDscAllowPlainTextPassword = $true },
          @{ NodeName = 'MARSDemo' }
       )
    }
    
    Configuration MARSAgentConfiguration {
       Import-DscResource -ModuleName cMicrosoftAzureRecoveryServices
       Node $AllNodes.NodeName {
          cMARSProxy MARSProxy {
             ProxyServer = 'https://myProxy'
             ProxyPort = 1010
             ProxyCredential = $ProxyCredential
             Ensure = 'Present'
			 Force = $true
          }
       }
    }

####Using cMARSRegistration resource####
The [cMARSRegistration](https://github.com/rchaganti/DSCResources/tree/master/cMicrosoftAzureRecoveryServices/DSCResources/cMARSRegistration) resource can be used to register the target system with Azure Backup vault. For registering with the backup vault, we need the vault credentials. These credentials can be downloaded from the [Azure Portal](http://manage.windowsazure.com) by navigating to the Backup Vault.

![](http://i.imgur.com/72VisGt.png)

Once these vault credentials are downloaded and stored in a local folder, we can use the *cMARSRegistration* resource configuration to register the server. The *VaultCredential* property can be used to specify the absolute path to the vault credentials file.

![](http://i.imgur.com/JVIsUxH.png)

    cMARSRegistration AgentRegistration {
        VaultCredential = 'C:\AzureBackup\DSCResourceDemo.VaultCredentials'
        Ensure = 'Present'
    }

Make a note that the path specified must be absolute path. When the registration is complete, you can see the server listed in the backup vault dashboard.

![](http://i.imgur.com/ogsKhOV.png)

Once the target system registration is complete, you can set the encryption pass phrase to encrypt the backup that is going to the backup vault. This is done using [cMARSEncryptionPhrase](https://github.com/rchaganti/DSCResources/tree/master/cMicrosoftAzureRecoveryServices/DSCResources/cMARSEncryptionPhrase) DSC resource.

Note that there is no method de-register a target system. There is no API available for that. Therefore, when you sent *Ensure='Absent'*, you just see a message that the *Absent* functionality is not implemented.

You can uninstall the recovery services agent when you don't need to backup the system anymore. However, remember that uninstalling the agent does not remove the system registration from the backup vault. You need to manually remove the server by navigating to the backup vault on the Azure management portal.

####Using cMARSEncryptionPhrase resource####
The *cMARSEncryptionPhrase* resource enables you to configure the  encryption settings for the MARS Agent Service. This encryption phrase will be used as the encryption key to encrypt the contents of your server backup.

![](http://i.imgur.com/Yl2gLI5.png)

The *EncryptionPassPhrase* is the only manadatory property and takes clear-text string as the passphrase. The resource module internally converts the clear-text string to secure string type required for the agent service configuration.

A secure string cannot be directly implemented as the MOF schema does not support a *securestring* type. This can be collected as a credential but it does not make a lot of sense. So, I left it as the clear-text string for now. This may change in a future release.

        cMARSEncryptionPhrase Passphrase {
            EncryptionPassPhrase = 'fawr123456789012345'
            Ensure = 'Present'
        }

Note that the length of the passphrase must be at least 16 characters. 

Once the passphrase is set, if you need to modify the passphrase, you can use the *Force* property.

        cMARSEncryptionPhrase Passphrase {
            EncryptionPassPhrase = 'fawr12345asf2012345'
            Force = $true
            Ensure = 'Present'
        }
  
Note that there is no way in the API (AFAIK) to remove the passphrase or encryption settings. Therefore, specifying *Ensure='Absent'* has no effect on the agent's encryption settings.