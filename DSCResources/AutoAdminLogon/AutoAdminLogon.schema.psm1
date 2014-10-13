Configuration AutoAdminLogon {
    Param (
        [Parameter(Mandatory)]
        [PSCredential] $AutoAdminCredential,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [String]$Ensure = "Present"
    )

    #Get the default domain name from the credential object
    if ($AutoAdminCredential.GetNetworkCredential().Domain) {
        $DefaultDomainName = $AutoAdminCredential.GetNetworkCredential().Domain
    } else {
        $DefaultDomainName = ""
    }

    Registry DefaultDomainName
    {
        Ensure = $Ensure
        Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
        ValueName = 'DefaultDomainName'
        ValueData = $DefaultDomainName
    }

    Registry DefaultUserName
    {
        Ensure = $Ensure
        Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
        ValueName = 'DefaultUserName'
        ValueData = $AutoAdminCredential.GetNetworkCredential().UserName
    }

    Registry DefaultPassword
    {
        Ensure = $Ensure
        Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
        ValueName = 'DefaultPassword'
        ValueData = $AutoAdminCredential.GetNetworkCredential().Password
    }

    Registry AutoAdminLogon
    {
        Ensure = $Ensure
        Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
        ValueName = 'AutoAdminLogon'
        ValueData = 1
    }
}