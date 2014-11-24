# DSCResources #
### Custom DSC resource modules for managing Windows OS configuration (miscellaneous) by [PowerShell Magazine](http://www.powershellmagazine.com "PowerShell Magazine"). ###

----------

This module contains a collection of miscellaneous DSC custom and composite resources for some generic Windows OS configuration tasks. 

At present, this DSC resource module includes 4 resources.
- [cHostsFile](https://github.com/rchaganti/DSCResources/tree/master/cWindowsOS/DSCResources/cHostsFile) is used to manage Hosts file entries.
- [cAutoAdminLogon](https://github.com/rchaganti/DSCResources/tree/master/cWindowsOS/DSCResources/cAutoAdminLogon) is used to add or remove auto administrator logon configuration. This is a composite resource.
- [cLoopBackCheck](https://github.com/rchaganti/DSCResources/tree/master/cWindowsOS/DSCResources/cLoopBackCheck) is used to enable or disable Loopback Check registry setting for web servers such as SharePoint Front End servers. This is a composite resource.
- [cDiskImage](https://github.com/rchaganti/DSCResources/tree/master/cWindowsOS/DSCResources/cDiskImage) is used to mount or dismount ISO images.

Before you can use any of these resources in a configuration script, you must first import the cWindowsOS module or a specific resource from this module.

    Import-DscResource -Module cWindowsOS
    Import-DscResource -Module cWindowsOS -Name cHostsFile
    Import-DscResource -Name cAutoAdminLogon

####Using cHostsFile resource####
The *cHostsFile* resource can used to manage the host file entries in Windows Operating System. This can be used to add or delete IPv4 and IPv6 hosts file entries.

![](http://i.imgur.com/V0gbqRz.png)

The *HostName* and *IPAddress* properties are both mandatory. This resource will check for this pair in the hosts file and then decide if it needs to be added or removed.

    cHostsFile HostsDemo {
        IPAddress = '10.10.10.1'
        HostName = 'Test10'
        Ensure = 'Present'
    }

####Using cDiskImage resource####
The *cDiskImage* resource can be used to mount or dismount ISO images on the target systems.

![](http://i.imgur.com/p7dpa0B.png)

When using this resource, both the *DriveLetter* and the *ImagePath* (ISO) must be specified. If the ISO image is already mounted with a different drive letter, this resource modifies it to the drive letter specified in the configuration script.

    cDiskImage DiskImageDemo {
        ImagePath = 'C:\Software\WS12R2.ISO'
        DriveLetter = 'F'
        Ensure = 'Present'
    }

The value specified for *ImagePath* can be an UNC path too. At present, there is no support for providing credentials to access the UNC path.

####Using cAutoAdminLogon resource####
The *cAutoAdminLogon* is a composite resource that enables or disables auto administrator logon.

![](http://i.imgur.com/gERjAXC.png)

The only mandatory parameter in this resource is the *AutoAdminCredential*. This takes a *PSCredential* object and therefore can be gathered using the *Get-Credential* cmdlet.

    $Credential = Get-Credential
    cAutoAdminLogon AutoAdminDemo {
        AutoAdminCredential = $Credential
        Ensure = 'Present'
    }

Make a note that when using Credentials in DSC configuration scripts, you must encrypt them using certificates. If the certificates cannot be deployed in a test or development environment, you can use the *[PsDscAllowPlainTextPassword](http://www.powershellmagazine.com/2013/09/26/using-the-credential-attribute-of-dsc-file-resource/)* attribute in the DSC configuration data. Remember that this is not recommended in production environment.

####Using cLoopBackCheck resource####
The *cLoopBackCheck* resource can be used to enable or disable the *LoopBackCheck* registry setting on web servers such as SharePoint Front End servers. This is a composite resource that internally uses the *Registry* DSC resource to modify predefined settings.

![](http://i.imgur.com/gNaDzBk.png)

The only property this resource requires is the *Ensure* property. By setting this to *Present*, the *LoopBackCheck* registry setting will be set and removed by setting it to *Absent*.

    cLoopBackCheck LoopbackDemo {
        Ensure = 'Present'
    }
