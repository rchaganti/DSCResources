# Fallback message strings in en-US
DATA localizedData
{
# same as culture = "en-US"
ConvertFrom-StringData @'
    MSOnlineBackupNotFound=MSOnlineBackup module was not found. This is required for the DSC resource.
    ProxySettingFound=ProxySetting configuration found.
    ProxySettingNotFound=Found no ProxySetting configuration.
    ForceFound=Force property found. Proxy configuration will be updated.
    ProxySettingExistsNoAction=ProxySetting Configuration {0} as proxy server Exists. No Action needed.
    ProxySettingDoesNotExistShouldAdd=ProxySetting Configuration {0} as proxy server does not exist. It will be added.
    ProxySettingExistsShouldRemove=ProxySetting Configuration {0} as proxy server Exists. It will be removed.
    ProxySettingDoesNotExistNoAction=ProxySetting Configuration {0} as proxy server does not exist. No action needed.
    UpdateProxySetting=Updating proxy setting configuration for {0}.
    UpdatedProxySetting=Updated proxy setting configuration for {0}.
    RemoveProxySetting=Removing proxy setting configuration for {0}.
    RemovedProxySetting=Removed proxy setting configuration for {0}.     
    AnErrorOccurred=An error occurred while verifying/updating proxy configuration: {0}.
    InnerException=Nested error trying to verifying/updating proxy configuration: {0}.
'@
}

if (Test-Path $PSScriptRoot\en-us)
{
    Import-LocalizedData LocalizedData -filename cMARSProxy.psd1
}

function Get-TargetResource
{
    [OutputType([Hashtable])]
    param (
        [Parameter(Mandatory)]
        [String] $ProxyServer
    )

    $Configuration = @{
        ProxyServer = $ProxyServer
    }

    try {
        $env:PSModulePath += ";$([System.Environment]::GetEnvironmentVariable("PSModulePath","Machine"))"
        Import-Module -Name MSOnlineBackup    
    }
    
    catch {
        throw $localizedData.MSOnlineBackupNotFound
    }

    try {
        $MachineSetting = Get-OBMachineSetting
        if ($MachineSetting.ProxySetting.Enabled) {
            if ($MachineSetting.ProxySetting.ProxyServer -eq $ProxyServer) {
                Write-Verbose $localizedData.ProxySettingFound
                $Configuration.Add('ProxyPort',$MachineSetting.ProxySetting.ProxyPort)
                $Configuration.Add('Ensure','Present')
            } else {
                Write-Verbose $localizedData.ProxySettingNotFound
                $Configuration.Add('Ensure','Absent')
            }
        } else {
            Write-Verbose $localizedData.ProxySettingNotFound
            $Configuration.Add('Ensure','Absent')
        }

        return $Configuration
    }

    catch {
        $exception = $_    
        Write-Verbose ($LocalizedData.AnErrorOccurred -f $exception.message)
        while ($exception.InnerException -ne $null)
        {
            $exception = $exception.InnerException
            Write-Verbose ($LocalizedData.InnerException -f $exception.message)
        }        
    }
}

function Set-TargetResource
{
    param (
        [Parameter(Mandatory)]
        [String] $ProxyServer,

        [Parameter()]
        [Uint32] $ProxyPort = 80,

        [Parameter()]
        [PSCredential] $ProxyCredential,

        [Parameter()]
        [Bool] $Force,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String] $Ensure = 'Present'
    )

    try {
        $env:PSModulePath += ";$([System.Environment]::GetEnvironmentVariable("PSModulePath","Machine"))"
        Import-Module -Name MSOnlineBackup    
    }
    
    catch {
        throw $localizedData.MSOnlineBackupNotFound
    }

    try {
        if ($Force -or $Ensure -eq 'Present') {
            Write-Verbose $LocalizedData.UpdateProxySetting
            if ($ProxyCredential) {
                Set-OBMachineSetting -ProxyServer $ProxyServer -ProxyPort $ProxyPort -ProxyUsername $ProxyCredential.UserName -ProxyPassword $ProxyCredential.Password
            } else {
                Set-OBMachineSetting -ProxyServer $ProxyServer -ProxyPort $ProxyPort
            }
            Write-Verbose $LocalizedData.UpdatedProxySetting
        } else {
            Write-Verbose ($LocalizedData.RemoveProxySetting -f $ProxyUserName)    
            Set-OBMachineSetting -NoProxy
            Write-Verbose ($LocalizedData.RemovedProxySetting -f $ProxyUserName)
        }
    }
    catch {
        $exception = $_    
        Write-Verbose ($LocalizedData.AnErrorOccurred -f $exception.message)
        while ($exception.InnerException -ne $null)
        {
            $exception = $exception.InnerException
            Write-Verbose ($LocalizedData.InnerException -f $exception.message)
        }
    }
}

function Test-TargetResource
{
    [OutputType([boolean])]
    param (
        [Parameter(Mandatory)]
        [String] $ProxyServer,

        [Parameter()]
        [Uint32] $ProxyPort = 80,

        [Parameter()]
        [PSCredential] $ProxyCredential,

        [Parameter()]
        [Bool] $Force,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String] $Ensure = 'Present'
    )

    try {
        $env:PSModulePath += ";$([System.Environment]::GetEnvironmentVariable("PSModulePath","Machine"))"
        Import-Module -Name MSOnlineBackup    
    }
    
    catch {
        throw $localizedData.MSOnlineBackupNotFound
    }

    try {
        if ($Force) {
            Write-Verbose $LocalizedData.ForceFound
            return $false
        } else {
            $MachineSetting = Get-OBMachineSetting
            $ProxySettingExists = (($MachineSetting.ProxySetting.ProxyPort -eq $ProxyPort) -and ($MachineSetting.ProxySetting.ProxyServer -eq $ProxyServer))
        
            if ($Ensure -eq 'Present') {
                if ($ProxySettingExists) {
                    Write-Verbose ($localizedData.ProxySettingExistsNoAction -f $ProxyServer)
                    return $true
                } else {
                    Write-Verbose ($localizedData.ProxySettingDoesNotExistShouldAdd -f $ProxyServer)
                    return $false
                }
            } else {
                if ($ProxySettingExists) {
                    Write-Verbose ($localizedData.ProxySettingExistsShouldRemove -f $ProxyUserName)
                    return $false
                } else {
                    Write-Verbose ($localizedData.ProxySettingDoesNotExistNoAction -f $ProxyUserName)
                    return $true
                }
            }
            
        }
    }

    catch {
        $exception = $_
        Write-Verbose ($LocalizedData.AnErrorOccurred -f $exception.message)
        while ($exception.InnerException -ne $null)
        {
            $exception = $exception.InnerException
            Write-Verbose ($LocalizedData.InnerException -f $exception.message)
        }
    }
}