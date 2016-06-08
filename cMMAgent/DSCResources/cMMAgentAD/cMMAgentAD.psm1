Import-LocalizedData -BindingVariable localizedData -filename cMMAgentAD.psd1 -BaseDirectory $PSScriptRoot -Verbose

function Get-TargetResource
{
    [OutputType([Hashtable])]
    param (
        [Parameter(Mandatory)]
        [Bool] $EnableAD
    )
    
    $configuration = @{
        EnableAD = $EnableAD
    }

    try {
        Write-Verbose $localizedData.GetMMAgentConfig
        $mmAgentConfig = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
        $adEnabled = $mmAgentConfig.ActiveDirectoryIntegrationEnabled -eq $true

        if ($EnableAD -eq $adEnabled) {
            Write-Verbose $localizedData.FoundAD
            $Configuration.Add('Ensure','Present')
        } else {
            Write-Verbose $localizedData.FoundNoAD
            $configuration.Add('Ensure','Absent')
        }

        return $configuration
    }

    catch {
        $exception = $_    
        Write-Verbose ($localizedData.AnErrorOccurred -f $exception.message)
        while ($exception.InnerException -ne $null)
        {
            $exception = $exception.InnerException
            Write-Verbose ($localizedData.InnerException -f $exception.message)
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
        Write-Verbose $localizedData.GetMMAgentConfig
        $mmAgentConfig = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'        
        if ($EnableAD)
        {
            Write-Verbose $localizedData.EnableAD
            $mmAgentConfig.EnableActiveDirectoryIntegration()
            $mmAgentConfig.ReloadConfiguration()
            Write-Verbose $localizedData.EnabledAD
        } else {
            Write-Verbose $localizedData.DisableAD
            $mmAgentConfig.DisableActiveDirectoryIntegration()
            $mmAgentConfig.ReloadConfiguration()
            Write-Verbose $localizedData.DisabledAD
        }
    }

    catch {
        $exception = $_    
        Write-Verbose ($localizedData.AnErrorOccurred -f $exception.message)
        while ($exception.InnerException -ne $null)
        {
            $exception = $exception.InnerException
            Write-Verbose ($localizedData.InnerException -f $exception.message)
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
        $mmAgentConfig = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
        $adEnabled = $mmAgentConfig.ActiveDirectoryIntegrationEnabled -eq $true

        if ($EnableAD) {
            if ($adEnabled) {
                Write-Verbose $localizedData.ADEnabledNoAction
                return $true
            } else {
                Write-Verbose $localizedData.ADNotEnabledShouldEnable
                return $false
            }
        } else {
            if ($adEnabled) {
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
        Write-Verbose ($localizedData.AnErrorOccurred -f $exception.message)
        while ($exception.InnerException -ne $null)
        {
            $exception = $exception.InnerException
            Write-Verbose ($localizedData.InnerException -f $exception.message)
        }
    }
}
