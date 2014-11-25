# Fallback message strings in en-US
DATA localizedData
{
# same as culture = "en-US"
ConvertFrom-StringData @'
    GetMMAgentConfig=Retrieving MMAgent Configuration object
    WorkSpaceIDExists=Azure Operational Insights with workspace ID {0} exists.
    WorkspaceIDDifferent=Azure Operational Insights with workspace ID {0} does not exist.
    AzureOpInsightNotEnabled=Azure Operational Insights is not enabled.
    EnableAzureOpInsights=Enabling Azure Operational Insights with Workspace ID {0}.
    EnabledAzureOpInsights=Enabled Azure Operational Insights with Workspace ID {0}.
    DisableAzureOpInsights=Disabling Azure Operational Insights with Workspace ID {0}.
    DisabledAzureOpInsights=Disabled Azure Operational Insights with Workspace ID {0}.
    UpdateWorkspaceWithAbsent=UpdateWorkspace property cannot be used when Ensure is set to Absent.
    UpdateWorkspaceFound=UpdateWorkspace property is set to True.
    AzureOpInsightsEnabledNoAction=Azure Operational Insights is enabled with Workspace ID {0}. No action Needed.
    AzureOpInsightsNotEnabledShouldEnable=Azure Operational Insights is not enabled with Workspace ID {0}. It will be enabled.
    AzureOpInsightsEnabledShouldRemoved=Azure Operational Insights is enabled with Workspace ID {0}. It will be disabled.
    AzureOpInsightsNotEnabledNoAction=Azure Operational Insights is not enabled with Workspace ID {0}. No action needed.
    ErrorDisablingOpInsights=There was an error disabling Azure Operational Insights.
    AnErrorOccurred=An error occurred while verifying/updating Azure OpInsights configuration: {0}.
    InnerException=Nested error trying to verifying/updating Azure OpInsights configuration: {0}.
'@
}

if (Test-Path $PSScriptRoot\en-us)
{
    Import-LocalizedData LocalizedData -filename cMMAgentOpInsights.psd1
}

function Get-TargetResource
{
    [OutputType([Hashtable])]
    param (
        [Parameter(Mandatory)]
        [String] $WorkspaceID,

        [Parameter(Mandatory)]
        [String] $WorkspaceKey
    )
    
    $Configuration = @{
        WorkspaceID = $WorkspaceID
        WorkspaceKey = $WorkspaceKey
    }

    try {
        Write-Verbose $localizedData.GetMMAgentConfig
        $MMAgentConfig = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
        if ($MMAgentConfig.AzureOperationalInsightsEnabled -eq $true) {
            if ($MMAgentConfig.AzureOperationalInsightsWorkspaceId -eq $WorkspaceID) {
                Write-Verbose ($localizedData.WorkSpaceIDExists -f $WorkspaceID)
                $Configuration.Add('Ensure','Present')    
            } else {
                Write-Verbose ($localizedData.WorkspaceIDDifferent -f $WorkspaceID)
                $Configuration.Add('Ensure','Absent') 
            }
        } else {
            Write-Verbose ($localizedData.AzureOpInsightNotEnabled)
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
        [String] $WorkspaceID,

        [Parameter(Mandatory)]
        [String] $WorkspaceKey,

        [Parameter()]
        [Bool] $UpdateWorkspace,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]$Ensure='Present'
    )     

    try {
        Write-Verbose $LocalizedData.GetMMAgentConfig
        $MMAgentConfig = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
    
        if ($Ensure -eq 'Present' -or ($UpdateWorkspace))
        {
            Write-Verbose ($LocalizedData.EnableAzureOpInsights -f $WorkspaceID)
            $MMAgentConfig.EnableAzureOperationalInsights($WorkspaceID, $WorkspaceKey)
        } else {
            Write-Verbose ($LocalizedData.DisableAzureOpInsights -f $WorkspaceID)
            #TODO: This results in an error for some reason but disables Azure OpInsights.
            #Workaround: Wrap it another try catch and don't send the error.
            try {
                $MMAgentConfig.DisableAzureOperationalInsights()
            }
            catch {
                if ($MMAgentConfig.AzureOperationalInsightsEnabled) {
                    $MMAgentConfig.ReloadConfiguration()
                    Write-Verbose ($LocalizedData.EnabledAzureOpInsights -f $WorkspaceID)
                } else {
                    throw $LocalizedData.ErrorDisablingOpInsights
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

function Test-TargetResource
{
    [OutputType([boolean])]
    param (
        [Parameter(Mandatory)]
        [String] $WorkspaceID,

        [Parameter(Mandatory)]
        [String] $WorkspaceKey,

        [Parameter()]
        [Bool] $UpdateWorkspace,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]$Ensure='Present'
    ) 
    
    if ($UpdateWorkspace -and ($Ensure -eq 'Absent')){
        throw $LocalizedData.UpdateWorkspaceWithAbsent
    }
    
    try {
        Write-Verbose $localizedData.GetMMAgentConfig
        $MMAgentConfig = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
        
        if ($MMAgentConfig.AzureOperationalInsightsEnabled -eq $true) {
            if ($MMAgentConfig.AzureOperationalInsightsWorkspaceId -eq $WorkspaceID) {
                $AzureOpInsightsEnabled = $true
            } else {
                $AzureOpInsightsEnabled = $false
            }
        } else {
            $AzureOpInsightsEnabled = $false
        }

        if ($UpdateWorkspace) {
            Write-Verbose $localizedData.UpdateWorkspaceFound
            return $false
        } elseif ($Ensure -eq 'Present') {
            if ($AzureOpInsightsEnabled) {
                Write-Verbose ($localizedData.AzureOpInsightsEnabledNoAction -f $WorkspaceID)
                return $true
            } else {
                Write-Verbose ($localizedData.AzureOpInsightsNotEnabledShouldEnable -f $WorkspaceID)
                return $false
            }
        } else {
            if ($AzureOpInsightsEnabled) {
                Write-Verbose ($localizedData.AzureOpInsightsEnabledShouldRemoved -f $WorkspaceID)
                return $false
            } else {
                Write-Verbose ($localizedData.AzureOpInsightsNotEnabledNoAction -f $WorkspaceID)
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