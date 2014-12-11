# Fallback message strings in en-US
DATA localizedData
{
# same as culture = "en-US"
ConvertFrom-StringData @'
    GetMMAgentConfig=Retrieving MMAgent Configuration object
    FoundAD=Found Active Directory Integration enabled.
    FoundNoAD=Found Active Directory integration disabled.
    EnableAD=Enabling Active Directory integration.
    EnabledAD=Enabled Active Directory integration.
    DisableAD=Disabling Active Directory integration.
    DisabledAD=Disabled Active Directory integration.
    ADEnabledNoAction=AD integration already enabled. No action needed.
    ADNotEnabledShouldEnable=AD integration not enabled. This will be enabled.
    ADEnabledShouldDisable=AD integration enabled. This will be disabled.
    ADNotEnabledNoAction=AD integration not enabled. No action needed.
    AnErrorOccurred=An error occurred while verifying/updating AD integration.
    InnerException=Nested error trying to verifying/updating AD integration.
'@
}

if (Test-Path $PSScriptRoot\en-us)
{
    Import-LocalizedData LocalizedData -filename cMMAgentAD.psd1
}

function Get-TargetResource
{
    [OutputType([Hashtable])]
    param (
        [Parameter(Mandatory)]
        [Bool] $EnableAD
    )
    
    $Configuration = @{
        EnableAD = $EnableAD
    }

    try {
        Write-Verbose $localizedData.GetMMAgentConfig
        $MMAgentConfig = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
        $ADEnabled = $MMAgentConfig.ActiveDirectoryIntegrationEnabled -eq $true

        if ($EnableAD -eq $ADEnabled) {
            Write-Verbose $localizedData.FoundAD
            $Configuration.Add('Ensure','Present')
        } else {
            Write-Verbose $localizedData.FoundNoAD
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
        [Bool] $EnableAD
    )     

    try {
        Write-Verbose $LocalizedData.GetMMAgentConfig
        $MMAgentConfig = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'        
        if ($EnableAD)
        {
            Write-Verbose $LocalizedData.EnableAD
            $MMAgentConfig.EnableActiveDirectoryIntegration()
            $MMAgentConfig.ReloadConfiguration()
            Write-Verbose $LocalizedData.EnabledAD
        } else {
            Write-Verbose $LocalizedData.DisableAD
            $MMAgentConfig.DisableActiveDirectoryIntegration()
            $MMAgentConfig.ReloadConfiguration()
            Write-Verbose $LocalizedData.DisabledAD
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
        [Bool] $EnableAD
    ) 

    try {
        Write-Verbose $localizedData.GetMMAgentConfig
        $MMAgentConfig = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
        $ADEnabled = $MMAgentConfig.ActiveDirectoryIntegrationEnabled -eq $true

        if ($EnableAD) {
            if ($ADEnabled) {
                Write-Verbose $localizedData.ADEnabledNoAction
                return $true
            } else {
                Write-Verbose $localizedData.ADNotEnabledShouldEnable
                return $false
            }
        } else {
            if ($ADEnabled) {
                Write-Verbose $localizedData.ADEnabledShouldDisable
                return $false
            } else {
                Write-Verbose $localizedData.ADNotEnabledNoAction
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