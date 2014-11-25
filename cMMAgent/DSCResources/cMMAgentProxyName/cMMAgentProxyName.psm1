# Fallback message strings in en-US
DATA localizedData
{
# same as culture = "en-US"
ConvertFrom-StringData @'
    GetMMAgentConfig=Retrieving MMAgent Configuration object
    FoundProxy=Found proxy with URL {0}
    FoundNoProxy=Found no proxy configuration with URL {0}
    SetProxyName=Setting proxy configuration to supplied URL {0}
    UpdatedProxyName=Updated proxy configuration to supplied URL {0}
    RemoveProxyName=Removing proxy configuration for URL {0}
    RemovedProxyName=Removed proxy configuration for URL {0}
    ProxyExistsNoAction=Proxy configuration exists with URL {0}. No action needed.
    ProxyDoesNotExistShouldAdd=Proxy configuration does not exist for URL {0}. It will be configured.
    ProxyExistsShouldRemove=Proxy configuration exists with URL {0}. It will be removed.
    ProxyDoesnotExistNoAction=Proxy configuration does not exist for URL {0}. No action needed.
    AnErrorOccurred=An error occurred while verifying/updating proxy configuration: {0}.
    InnerException=Nested error trying to verifying/updating proxy configuration: {0}.
'@
}

if (Test-Path $PSScriptRoot\en-us)
{
    Import-LocalizedData LocalizedData -filename cMMAgentProxyName.psd1
}

function Get-TargetResource
{
    [OutputType([Hashtable])]
    param (
        [Parameter(Mandatory)]
        [ValidateScript({$_.Startswith('http') -or $_.Startswith('https')})]
        [String] $ProxyName
    )
    
    $Configuration = @{
        ProxyName = $ProxyName
    }

    try {
        Write-Verbose $localizedData.GetMMAgentConfig
        $MMAgentConfig = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
        if ($MMAgentConfig.proxyUrl -eq $ProxyName) {
            $Configuration.Add('Ensure','Present')
        } else {
            Write-Verbose ($localizedData.FoundNoProxy -f $ProxyName)
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
        [ValidateScript({$_.Startswith('http') -or $_.Startswith('https')})]
        [String] $ProxyName,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]$Ensure='Present'
    )     

    try {
        Write-Verbose $LocalizedData.GetMMAgentConfig
        $MMAgentConfig = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'        
        if ($Ensure -eq 'Present')
        {
            Write-Verbose ($LocalizedData.SetProxyName -f $ProxyName)
            $MMAgentConfig.SetProxyUrl($ProxyName)
            $MMAgentConfig.ReloadConfiguration()
            Write-Verbose ($LocalizedData.UpdatedProxyName -f $ProxyName)
        } else {
            Write-Verbose ($LocalizedData.RemoveProxyName -f $ProxyName)
            $MMAgentConfig.SetProxyUrl($null)
            $MMAgentConfig.ReloadConfiguration()
            Write-Verbose ($LocalizedData.RemovedProxyName -f $ProxyName)
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
        [ValidateScript({$_.Startswith('http') -or $_.Startswith('https')})]
        [String] $ProxyName,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]$Ensure='Present'
    ) 

    try {
        Write-Verbose $localizedData.GetMMAgentConfig
        $MMAgentConfig = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
        $ProxyExists = $MMAgentConfig.proxyUrl -eq $ProxyName

        if ($Ensure -eq 'Present') {
            if ($ProxyExists) {
                Write-Verbose ($localizedData.ProxyExistsNoAction -f $ProxyName)
                return $true
            } else {
                Write-Verbose ($localizedData.ProxyDoesNotExistShouldAdd -f $ProxyName)
                return $false
            }
        } else {
            if ($ProxyExists) {
                Write-Verbose ($localizedData.ProxyExistsShouldRemove -f $ProxyName)
                return $false
            } else {
                Write-Verbose ($localizedData.ProxyDoesnotExistNoAction -f $ProxyName)
                return $true
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