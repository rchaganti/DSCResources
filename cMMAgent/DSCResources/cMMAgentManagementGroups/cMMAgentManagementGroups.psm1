Import-LocalizedData -BindingVariable localizedData -filename cMMAgentManagementGroups.psd1 -BaseDirectory $PSScriptRoot -Verbose

function Get-TargetResource
{
    [OutputType([Hashtable])]
    param (
        [Parameter(Mandatory)]
        [String] $ManagementGroupName,

        [Parameter(Mandatory)]
        [String] $ManagementServerName
    )
    
    $configuration = @{
        managementGroupName = $ManagementGroupName
        managementServerName = $ManagementServerName
    }

    try {
        Write-Verbose $localizedData.GetMMAgentConfig
        $mmAgentConfig = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'

        #This try-catch is a workaround for the COM method failure when the specified group does not exist
        try {
            Write-Verbose $localizedData.GetManagementGroup
            $managementGroup = $mmAgentConfig.GetManagementGroup($ManagementGroupName)
        }
        catch {
            Write-Verbose $localizedData.ManagementGroupNotFound
            $configuration.Add('Ensure','Absent')
        }

        if ($managementGroup) {
            Write-Verbose $localizedData.ManagementGroupFound
            $configuration.Add('Ensure','Present')
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
        [String] $managementGroupName,

        [Parameter(Mandatory)]
        [String] $managementServerName,

        [Parameter()]
        [UInt32] $managementServerPort = 5723,

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
        [UInt32] $managementServerPort = 5723,

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