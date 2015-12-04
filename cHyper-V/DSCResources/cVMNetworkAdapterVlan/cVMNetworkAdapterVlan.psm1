# Fallback message strings in en-US
DATA localizedData
{
    # same as culture = "en-US"
ConvertFrom-StringData @'    
    HyperVModuleNotFound=Hyper-V PowerShell Module not found.
    VMNameAndManagementTogether=VMName cannot be provided when ManagementOS is set to True.
    MustProvideVMName=Must provide VMName parameter when ManagementOS is set to False.
    GetVMNetAdapter=Getting VM Network Adapter information.
    FoundVMNetAdapter=Found VM Network Adapter.
    NoVMNetAdapterFound=No VM Network Adapter found.
    VMNetAdapterDoesNotExist=VM Network Adapter does not exist.
    PerformVMVlanSet=Perfoming VM Network Adapter VLAN setting configuration.
    IgnoreVlan=Ignoring VLAN configuration when the opeartion mode chosen is Untagged.
    VlanIdRequiredInAccess=VlanId must be specified when chosen operation mode is Access.
    MustProvideNativeVlanId=NativeVlanId must be specified when chosen operation mode is Trunk.
    PrimaryVlanIdRequired=PrimaryVlanId is required when the chosen operation mode is Community or Isolated or Promiscuous.
    AccessVlanMustChange=VlanId in Access mode is different. It will be changed.
    AdaptersExistsWithVlan=VM Network adapter exists with required VLAN configuration.
    NativeVlanMustChange=NativeVlanId in Trunk mode is different and it wil be changed.
    AllowedVlanListMustChange=AllowedVlanIdList is different in trunk mode. It will be changed.
    PrimaryVlanMustChange=PrimaryVlanId is different and must be changed.
    SecondaryVlanMustChange=SecondaryVlanId is different and must be changed.
    SecondaryVlanListMustChange=SecondaryVlanIdList is different and must be changed.
    AdapterExistsWithDifferentVlanMode=VM Network adapter exists with different Vlan configuration. It will be fixed.
'@
}

if (Test-Path "$PSScriptRoot\$PSCulture")
{
    Import-LocalizedData LocalizedData -filename "cVMNetworkAdapterVlan.psd1" -BaseDirectory "$PSScriptRoot\$PSCulture"
}

Function Get-TargetResource {
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
    Param (
        [Parameter(Mandatory)]
        [String] $Name
    )

    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw $localizedData.HyperVModuleNotFound
    }

    $Arguments = @{
        Name = $Name
    }

    Write-Verbose $localizedData.GetVMNetAdapter
    try {
        $AdapterExists = Get-VMNetworkAdapter @Arguments -ErrorAction Stop

        if ($AdapterExists) {
            Write-Verbose $localizedData.FoundVMNetAdapter
            $Configuration = $Arguments
            $Configuration.Remove('Name')
            $Configuration.Add('AdapterMode',$AdapterExists.VlanSetting.OperationMode)
            $Configuration.Add('VlanId',$AdapterExists.VlanSetting.AccessVlanId)
            $Configuration.Add('NativeVlanId',$AdapterExists.VlanSetting.NativeVlanId)
            $Configuration.Add('PrimaryVlanId',$AdapterExists.VlanSetting.PrimaryVlanId)
            $Configuration.Add('SecondaryVlanId',$AdapterExists.VlanSetting.SecondaryVlanId)
            $Configuration.Add('SecondaryVlanIdList',$AdapterExists.VlanSetting.SecondaryVlanIdListString)
            $Configuration.Add('AllowedVlanIdList',$AdapterExists.VlanSetting.AllowedVlanIdListString)
        }

        $Configuration
    } 
    catch {
        Write-Error $_
    }
}

Function Set-TargetResource {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]
        [String] $Name,

        [Parameter()]
        [Bool] $ManagementOS,

        [Parameter()]
        [String] $VMName,

        [Parameter()]
        [ValidateSet('Untagged','Access','Trunk','Communnity','Isolated','Promiscuous')]
        [String] $AdapterMode = 'Untagged',

        [Parameter()]
        [uint32] $VlanId,

        [Parameter()]
        [uint32] $NativeVlanId,

        [Parameter()]
        [String] $AllowedVlanIdList,
        
        [Parameter()]
        [uint32] $PrimaryVlanId,

        [Parameter()]
        [uint32] $SecondaryVlanId,

        [Parameter()]
        [String] $SecondaryVlanIdList
    )

    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw $localizedData.HyperVModuleNotFound
    }

    if ($VMName -and $ManagementOS) {
        throw $localizedData.VMNameAndManagementTogether
    }

    if ((-not $ManagementOS) -and (-not $VMName)) {
        throw $localizedData.MustProvideVMName
    }

    $Arguments = @{
        Name = $Name
    }

    if ($VMName) {
        $Arguments.Add('VMName',$VMName)
    } elseif ($ManagementOS) {
        $Arguments.Add('ManagementOS', $true)
    }

    try {
        Write-Verbose $localizedData.GetVMNetAdapter
        $AdapterExists = Get-VMNetworkAdapter @Arguments -ErrorAction Stop
        if ($AdapterExists) {
            Write-Verbose $localizedData.FoundVMNetAdapter
            $SetArguments = $Arguments
            $SetArguments.Remove('Name')
            $SetArguments.Add('VMNetworkAdapterName',$Name)
            switch ($AdapterMode) {
                'Untagged' {
                    $SetArguments.Add('Untagged',$true)
                    break
                }
    
                'Access' {
                    $SetArguments.Add('Access',$true)
                    $SetArguments.Add('VlanId',$VlanId)
                    break
                }
    
                'Trunk' {
                    $SetArguments.Add('Trunk',$true)
                    $SetArguments.Add('NativeVlanId',$NativeVlanId)
                    if ($AllowedVlanIdList) {
                        $SetArguments.Add('AllowedVlanIdList',$AllowedVlanIdList)
                    }
                    break
                }
    
                'Community' {
                    $SetArguments.Add('Community',$true)
                    $SetArguments.Add('PrimaryVlanId',$PrimaryVlanId)
                    if ($SecondaryVlanId) {
                        $SetArguments.Add('SecondaryVlanId',$SecondaryVlanId)
                    }
                    break
                }
    
                'Isolated' {
                    $SetArguments.Add('Isolated',$true)
                    $SetArguments.Add('PrimaryVlanId',$PrimaryVlanId)
                    if ($SecondaryVlanId) {
                        $SetArguments.Add('SecondaryVlanId',$SecondaryVlanId)
                    }
                    break
                }
    
                'Promiscuous' {
                    $SetArguments.Add('Promiscuous',$true)
                    $SetArguments.Add('PrimaryVlanId', $PrimaryVlanId)
                    if ($SecondaryVlanIdList) {
                        $SetArguments.Add('SecondaryVlanIdList', $SecondaryVlanIdList)
                    }
                    break
                }
            }
        }
        
        Write-Verbose $localizedData.PerformVMVlanSet
        Set-VMNetworkAdapterVlan @SetArguments -ErrorAction Stop
    }
    catch {
        Write-Error $_
    }
}

Function Test-TargetResource {
	[CmdletBinding()]
	[OutputType([System.Boolean])]
    Param (
        [Parameter(Mandatory)]
        [String] $Name,

        [Parameter()]
        [Bool] $ManagementOS,

        [Parameter()]
        [String] $VMName,

        [Parameter()]
        [ValidateSet('Untagged','Access','Trunk','Communnity','Isolated','Promiscuous')]
        [String] $AdapterMode = 'Untagged',

        [Parameter()]
        [uint32] $VlanId,

        [Parameter()]
        [uint32] $NativeVlanId,

        [Parameter()]
        [String] $AllowedVlanIdList,
        
        [Parameter()]
        [uint32] $PrimaryVlanId,

        [Parameter()]
        [uint32] $SecondaryVlanId,

        [Parameter()]
        [String] $SecondaryVlanIdList
    )

    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw $localizedData.HyperVModuleNotFound
    }

    if ($VMName -and $ManagementOS) {
        throw $localizedData.VMNameAndManagementTogether
    }

    if ((-not $ManagementOS) -and (-not $VMName)) {
        throw $localizedData.MustProvideVMName
    }

    $Arguments = @{
        Name = $Name
    }

    if ($VMName) {
        $Arguments.Add('VMName',$VMName)
    } elseif ($ManagementOS) {
        $Arguments.Add('ManagementOS', $true)
    }
    
    switch ($AdapterMode) {
        'Untagged' {
            if ($VlanId -or $NativeVlanId -or $PrimaryVlanId -or $SecondaryVlanId -or $AllowedVlanIdList -or $SecondaryVlanIdList) {
                Write-Verbose $localizedData.IgnoreVlan
            }
            break
        }

        'Access' {
            if (-not $VlanId) {
                throw $localizedData.VlanIdRequiredInAccess
            }
            break
        }

        'Trunk' {
            if (-not $NativeVlanId) {
                throw $localizedData.MustProvideNativeVlanId
            }
            break
        }

        'Community' {
            if (-not $PrimaryVlanId) {
                throw $localizedData.PrimaryVlanIdRequired    
            }
            break
        }

        'Isolated' {
            if (-not $PrimaryVlanId) {
                throw $localizedData.PrimaryVlanIdRequired
            }
            break
        }

        'Promiscuous' {
            if (-not $PrimaryVlanId) {
                throw $localizedData.PrimaryVlanIdRequired
            }
            break
        }
    }

    try {
        #There is a remote timing issue that occurs when VLAN is set just after creating a VM Adapter. This needs more investigation. Sleep until then.
        Start-Sleep -Seconds 10
        Write-Verbose $localizedData.GetVMNetAdapter
        $AdapterExists = Get-VMNetworkAdapter @Arguments -ErrorAction Stop
    
        if ($AdapterExists) {
            Write-Verbose $localizedData.FoundVMNetAdapter
            if ($AdapterExists.VlanSetting.OperationMode -eq $AdapterMode) {
                switch ($AdapterExists.VlanSetting.OperationMode) {
                    'Access' {
                        if ($VlanId -ne $AdapterExists.VlanSetting.AccessVlanId) {
                            Write-Verbose $localizedData.AccessVlanMustChange
                            return $false
                        } else {
                            Write-Verbose $localizedData.AdaptersExistsWithVlan
                            return $true
                        }
                        break
                    }

                    'Trunk' {
                        if ($NativeVlanId -ne $AdapterExists.VlanSetting.NativeVlanId) {
                            Write-Verbose $localizedData.NativeVlanMustChange
                            return $false
                        } elseif ($AllowedVlanIdList -ne $AdapterMode.VlanSetting.AllowedVlanIdListString) {
                            Write-Verbose $localizedData.AllowedVlanListMustChange
                            return $false
                        } else {
                            Write-Verbose $localizedData.AdaptersExistsWithVlan
                            return $true
                        }
                        break
                    }

                    'Untagged' {
                        if ($AdapterMode -eq 'Untagged') {
                            Write-Verbose $localizedData.AdaptersExistsWithVlan
                            Write-Verbose $localizedData.IgnoreVlan
                            return $true
                        }
                        break
                    }

                    ('Community' -or 'isolated') {
                        if ($PrimaryVlanId -ne $AdapterExists.VlanSetting.PrimaryVlanId) {
                            Write-Verbose $localizedData.PrimaryVlanMustChange
                            return $false
                        } elseif ($SecondaryVlanId -ne $AdapterExists.VlanSetting.SecondaryVlanId) {
                            Write-Verbose $localizedData.SecondaryVlanMustChange
                            return $false
                        } else {
                            Write-Verbose $localizedData.AdaptersExistsWithVlan
                            return $true
                        }
                        break
                    }

                    'Promiscuous' {
                        if ($PrimaryVlanId -ne $AdapterExists.VlanSetting.PrimaryVlanId) {
                            Write-Verbose $localizedData.PrimaryVlanMustChange
                            return $false
                        } elseif ($SecondaryVlanIdList -ne $AdapterExists.VlanSetting.SecondaryVlanIdListString) {
                            Write-Verbose $localizedData.SecondaryVlanListMustChange
                            return $false
                        } else {
                            Write-Verbose $localizedData.AdaptersExistsWithVlan
                            return $true
                        }
                    }
                }
            } else {
                Write-Verbose $localizedData.AdapterExistsWithDifferentVlanMode
                return $false
            }
        } else {
            Write-Warning $localizedData.VMNetAdapterDoesNotExist
        }
    }
    catch {
        Write-Error $_
    }
}