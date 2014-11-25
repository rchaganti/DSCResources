# Fallback message strings in en-US
DATA localizedData
{
# same as culture = "en-US"
ConvertFrom-StringData @'
    GetMMAgentConfig=Retrieving MMAgent Configuration object.
    FoundProxyUser=Found proxyusername as supplied {0}.
    FoundNoProxyUser=Found no proxyusername as supplied {0}.
    SetProxyName=Setting proxy configuration to supplied URL {0}.
    UpdateProxyCredential=Updating proxy credential configuration to supplied username {0} and password.
    UpdatedProxyCredential=Updated/configured proxy credential to supplied username {0} and password.
    SetProxyCredential=Setting proxy credential to supplied username {0} and password.
    RemoveProxyCredential=Removing proxy credential for username {0}.
    RemovedProxyCredential=Removed proxy credential for username {0}.
    UpdateCrdentialFound=Update Crdential property found.
    ProxyUserExistsNoAction=Proxy credential configuration exists with username {0}. No action needed.
    ProxyUserDoesNotExistShouldAdd=Proxy credential configuration does not exist for username {0}. It will be configured.
    ProxyUserExistsShouldRemove=Proxy credential configuration exists for username {0}. It will be removed.
    ProxyUserDoesnotExistNoAction=Proxy credential configuration does not exist for username {0}. No action needed.
    UpdateCredentialWithAbsent=UpdateCredential property cannot be set to True if Ensure is set to Absent.
    AnErrorOccurred=An error occurred while verifying/updating proxy configuration: {0}.
    InnerException=Nested error trying to verifying/updating proxy configuration: {0}.
'@
}

if (Test-Path $PSScriptRoot\en-us)
{
    Import-LocalizedData LocalizedData -filename cMMAgentProxyCredential.psd1
}

function Get-TargetResource
{
    [OutputType([Hashtable])]
    param (
        [Parameter(Mandatory)]
        [String] $ProxyUserName,

        [Parameter(Mandatory)]
        [PSCredential] $ProxyUserPassword
    )
    
    $Configuration = @{
        ProxyUserName = $ProxyUserName
        ProxyUserPassword = $ProxyUserPassword
    }

    try {
        Write-Verbose $localizedData.GetMMAgentConfig
        $MMAgentConfig = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
        if ($MMAgentConfig.proxyUsername -eq $ProxyUserName) {
            Write-Verbose ($localizedData.FoundProxyUser -f $ProxyUserName)
            $Configuration.Add('Ensure','Present')
        } else {
            Write-Verbose ($localizedData.FoundNoProxyUser -f $ProxyUserName)
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
        [String] $ProxyUserName,

        [Parameter(Mandatory)]
        [PSCredential] $ProxyUserPassword,

        [Parameter()]
        [Bool] $UpdateCredential,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String] $Ensure='Present'
    )     

    try {
        Write-Verbose $LocalizedData.GetMMAgentConfig
        $MMAgentConfig = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
        if ($UpdateCredential) {
            Write-Verbose $LocalizedData.UpdateProxyCredential
            $MMAgentConfig.SetProxyCredentials($ProxyUserName, $ProxyUserPassword.GetNetworkCredential().Password)
            Write-Verbose $LocalizedData.UpdatedProxyCredential
        } elseif ($Ensure -eq 'Present') {
            Write-Verbose ($LocalizedData.SetProxyCredential -f $ProxyUserName)    
            $MMAgentConfig.SetProxyCredentials($ProxyUserName, $ProxyUserPassword.GetNetworkCredential().Password)
            Write-Verbose ($LocalizedData.UpdatedProxyCredential -f $ProxyUserName)
        } else {
            Write-Verbose ($LocalizedData.RemoveProxyCredential -f $ProxyUserName)    
            $MMAgentConfig.SetProxyCredentials($null,$null)
            Write-Verbose ($LocalizedData.RemovedProxyCredential -f $ProxyUserName)
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
        [String] $ProxyUserName,

        [Parameter(Mandatory)]
        [PSCredential] $ProxyUserPassword,

        [Parameter()]
        [Bool] $UpdateCredential,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String] $Ensure='Present'
    )     

    if ($UpdateCredential -and ($Ensure -eq 'Absent')) {
        throw $LocalizedData.UpdateCredentialWithAbsent
    }

    try {
        if ($UpdateCredential) {
            Write-Verbose $LocalizedData.UpdateCrdentialFound
            return $false
        } else {
            Write-Verbose $localizedData.GetMMAgentConfig
            $MMAgentConfig = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'

            $ProxyUserExists = $MMAgentConfig.proxyUsername -eq $ProxyUserName
        
            if ($Ensure -eq 'Present') {
                if ($ProxyUserExists) {
                    Write-Verbose ($localizedData.ProxyUserExistsNoAction -f $ProxyUserName)
                    return $true
                } else {
                    Write-Verbose ($localizedData.ProxyUserDoesNotExistShouldAdd -f $ProxyUserName)
                    return $false
                }
            } else {
                if ($ProxyUserExists) {
                    Write-Verbose ($localizedData.ProxyUserExistsShouldRemove -f $ProxyUserName)
                    return $false
                } else {
                    Write-Verbose ($localizedData.ProxyUserDoesnotExistNoAction -f $ProxyUserName)
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