# Fallback message strings in en-US
DATA localizedData
{
# same as culture = "en-US"
ConvertFrom-StringData @'
    GetMMAgentConfig=Retrieving MMAgent Configuration object.
    GetManagementGroup=Getting Management Group.
    ManagementGroupNotFound=Management Group not found.
    ManagementGroupFound=Management group found.
    ShouldUpdateManagementGroup=Management group configurtion will be updated.
    ManagementGroupFoundNoActionNeeded=Management group found. No action needed.
    ManagementGroupDoesnotExistMustCreate=Management group does not exist. It will be configured.
    ManagementGroupFoundMustDelete=Management group found. It will be removed.
    ManagementGroupNotFoundNoActionNeeded=Management group not found. No action needed.
    UpdateActionAccount=Action account Credentials will be updated.
    UpdateActionAccountComplete=Action Account Credentials updated.
    ActionAccountNotSpecified=Action Account credentials must be specified when setting Force property to True.
    AnErrorOccurred=An error occurred while working with management group.
    InnerException=Nested error during management group configuration.
    AddingManagementGroup=Adding Management Group configuration.
    AddedManagementGroup=Added Management Group configuration.
    RemovingManagementGroup=Removing Management Group Configuration.
    RemovedManagementGroup=Removed Management Group Configuration.
'@
}

if (Test-Path $PSScriptRoot\en-us)
{
    Import-LocalizedData LocalizedData -filename cMMAgentManagementGroups.psd1
}

function Get-TargetResource
{
    [OutputType([Hashtable])]
    param (
        [Parameter(Mandatory)]
        [String] $managementGroupName,

        [Parameter(Mandatory)]
        [String] $managementServerName
    )
    
    $Configuration = @{
        managementGroupName = $managementGroupName
        managementServerName = $managementServerName
    }

    try {
        Write-Verbose $localizedData.GetMMAgentConfig
        $MMAgentConfig = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'

        #This try-catch is a workaround for the COM method failure when the specified group does not exist
        try {
            Write-Verbose $localizedData.GetManagementGroup
            $ManagementGroup = $MMAgentConfig.GetManagementGroup($managementGroupName)
        }
        catch {
            Write-Verbose $localizedData.ManagementGroupNotFound
            $Configuration.Add('Ensure','Absent')
        }

        if ($ManagementGroup) {
            Write-Verbose $localizedData.ManagementGroupFound
            $Configuration.Add('Ensure','Present')
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
        [String] $managementGroupName,

        [Parameter(Mandatory)]
        [String] $managementServerName,

        [Parameter()]
        [Int] $managementServerPort = 5723,

        [Parameter()]
        [PSCredential] $actionAccountCredential,

        [Parameter()]
        [Bool] $Force,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String] $Ensure = 'Present'
    )     

    try {
        Write-Verbose $LocalizedData.GetMMAgentConfig
        $MMAgentConfig = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
        
        if ($Force) {
            if ($actionAccountCredential) {
                if (-not ($actionAccountCredential.GetNetworkCredential().Domain)) {
                    $ActionDomain = $null
                } else {
                    $ActionDomain = $actionAccountCredential.GetNetworkCredential().Domain
                }
                Write-Verbose $LocalizedData.UpdateActionAccount
                $MMAgentConfig.UpdateActionAccount($managementGroupName, $ActionDomain, $actionAccountCredential.GetNetworkCredential().UserName, $actionAccountCredential.GetNetworkCredential().Password)
                $MMAgentConfig.ReloadConfiguration()
                Write-Verbose $LocalizedData.UpdateActionAccountComplete
            } else {
                throw $LocalizedData.ActionAccountNotSpecified
            }
        } elseif ($Ensure -eq 'Present') {
            Write-Verbose $LocalizedData.AddingManagementGroup
            if ($actionAccountCredential) {
                if (-not ($actionAccountCredential.GetNetworkCredential().Domain)) {
                    $ActionDomain = $null
                } else {
                    $ActionDomain = $actionAccountCredential.GetNetworkCredential().Domain
                }
                $MMAgentConfig.AddManagementGroup($managementGroupName,$managementServerName,$managementServerPort, $ActionDomain, $actionAccountCredential.GetNetworkCredential().UserName, $actionAccountCredential.GetNetworkCredential().Password)
            } else {
                $MMAgentConfig.AddManagementGroup($managementGroupName,$managementServerName,$managementServerPort)                
            }
            $MMAgentConfig.ReloadConfiguration()
            Write-Verbose $LocalizedData.AddedManagementGroup
        } elseif ($Ensure -eq 'Absent') {
            Write-Verbose $LocalizedData.RemovingManagementGroup
            $MMAgentConfig.RemoveManagementGroup($managementGroupName)
            $MMAgentConfig.ReloadConfiguration()
            Write-Verbose $LocalizedData.RemovedManagementGroup
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
        [String] $managementGroupName,

        [Parameter(Mandatory)]
        [String] $managementServerName,

        [Parameter()]
        [Int] $managementServerPort = 5723,

        [Parameter()]
        [PSCredential] $actionAccountCredential,

        [Parameter()]
        [Bool] $Force,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String] $Ensure = 'Present'
    )

    try {
        Write-Verbose $localizedData.GetMMAgentConfig
        $MMAgentConfig = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
        
        try {
            $ManagementGroup = $MMAgentConfig.GetManagementGroup($managementGroupName)
        }
        catch {
            Write-Verbose $localizedData.ManagementGroupNotFound
        }

        if ($Force) {
            Write-Verbose $localizedData.ShouldUpdateManagementGroup
            return $false
        } elseif ($Ensure -eq 'Present') {
            if ($ManagementGroup) {
                Write-Verbose $localizedData.ManagementGroupFoundNoActionNeeded
                return $true
            } else {
                Write-Verbose $localizedData.ManagementGroupDoesnotExistMustCreate
                return $false
            }
        } else {
            if ($ManagementGroup) {
                Write-Verbose $localizedData.ManagementGroupFoundMustDelete
                return $false
            } else {
                Write-Verbose $localizedData.ManagementGroupNotFoundNoActionNeeded
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