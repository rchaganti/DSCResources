# Fallback message strings in en-US
DATA localizedData
{
    # same as culture = "en-US"
ConvertFrom-StringData @'    
    VMNameAndManagementTogether=VMName cannot be provided when ManagementOS is set to True.
    MustProvideVMName=Must provide VMName parameter when ManagementOS is set to False.
    GetVMNetAdapter=Getting VM Network Adapter information.
    FoundVMNetAdapter=Found VM Network Adapter.
    NoVMNetAdapterFound=No VM Network Adapter found.
    StaticAndDynamicTogether=StaticMacAddress and DynamicMacAddress parameters cannot be provided together.
    ModifyVMNetAdapter=VM Network Adapter exists with different configuration. This will be modified.
    EnableDynamicMacAddress=VM Network Adapter exists but without Dynamic MAC address setting.
    EnableStaticMacAddress=VM Network Adapter exists but without static MAC address setting.
    PerformVMNetModify=Performing VM Network Adapter configuration changes.
    CannotChangeHostAdapterMacAddress=VM Network adapter in configuration is a host adapter. Its configuration cannot be modified.
    AddVMNetAdapter=Adding VM Network Adapter.
    RemoveVMNetAdapter=Removing VM Network Adapter.
    VMNetAdapterExistsNoActionNeeded=VM Network Adapter exists with requested configuration. No action needed.
    VMNetAdapterDoesNotExistShouldAdd=VM Network Adapter does not exist. It will be added.
    VMNetAdapterExistsShouldRemove=VM Network Adapter Exists. It will be removed.
    VMNetAdapterDoesNotExistNoActionNeeded=VM Network adapter does not exist. No action needed.
    SwitchIsDifferent=Net Adapter is not connected to the requested switch.
    PerformSwitchConnect=Connecting VM Net adapter to the right switch.
'@
}

if (Test-Path "$PSScriptRoot\$PSCulture")
{
    Import-LocalizedData LocalizedData -filename "cVMNetworkAdapter.psd1" -BaseDirectory "$PSScriptRoot\$PSCulture"
}

Function Get-TargetResource {
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
    Param (
        [Parameter(Mandatory)]
        [String] $Id,

        [Parameter(Mandatory)]
        [String] $Name,        

        [Parameter(Mandatory)]
        [String] $SwitchName,

        [Parameter(Mandatory)]
        [String] $VMName
    )

    $Configuration = @{
        Name = $Name
        SwitchName = $SwitchName
        VMName = $VMName
    }

    $Arguments = @{
        Name = $Name
    }

    if ($VMName -ne 'Management OS') {
        $Arguments.Add('VMName',$VMName)
    } else {
        $Arguments.Add('ManagementOS', $true)
        $Arguments.Add('SwitchName', $SwitchName)
    }

    Write-Verbose $localizedData.GetVMNetAdapter
    $NetAdapter = Get-VMNetworkAdapter @Arguments -ErrorAction SilentlyContinue

    if ($NetAdapter) {
        Write-Verbose $localizedData.FoundVMNetAdapter
        if ($VMName -eq 'Management OS') {
            $Configuration.Add('StaticMacAddress', $NetAdapter.MacAddress)
        } elseif ($NetAdapter.VMName) {
            $Configuration.Add('StaticMacAddress', $NetAdapter.MacAddress)   
            $Configuration.Add('DynamicMacAddress', $NetAdapter.DynamicMacAddressEnabled)
        }
        $Configuration.Add('Ensure','Present')
    } else {
        Write-Verbose $localizedData.NoVMNetAdapterFound
        $Configuration.Add('Ensure','Absent')
    }

    $Configuration
}

Function Set-TargetResource {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]
        [String] $Id,
        
        [Parameter(Mandatory)]
        [String] $Name,

        [Parameter(Mandatory)]
        [String] $SwitchName,

        [Parameter(Mandatory)]
        [String] $VMName,

        [Parameter()]
        [Bool] $DynamicMacAddress,

        [Parameter()]
        [String] $StaticMacAddress,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String] $Ensure='Present'
    )

    if ($DynamicMacAddress -and $StaticMacAddress) {
        throw $localizedData.StaticAndDynamicTogether
    }

    $Arguments = @{
        Name = $Name
    }

    if ($VMName -ne 'Management OS') {
        $Arguments.Add('VMName',$VMName)
    } else {
        $Arguments.Add('ManagementOS', $true)
        $Arguments.Add('SwitchName', $SwitchName)
    }
    
    Write-Verbose $localizedData.GetVMNetAdapter
    $NetAdapterExists = Get-VMNetworkAdapter @Arguments -ErrorAction SilentlyContinue
    
    if ($Ensure -eq 'Present') {
        if ($NetAdapterExists) {
            Write-Verbose $localizedData.FoundVMNetAdapter
            if (($VMName -ne 'Management OS')) {
                Write-Verbose $localizedData.ModifyVMNetAdapter
                $SetArguments = @{
                    VMNetworkAdapter = $NetAdapterExists
                }

                if ($DynamicMacAddress) {
                    if (-not $NetAdapterExists.DynamicMacAddressEnabled) {
                        Write-Verbose $localizedData.EnableDynamicMacAddress
                        $SetArguments.Add('DynamicMacAddress',$true)
                    }
                } elseif ($StaticMacAddress) {
                    if ($StaticMacAddress -ne $NetAdapterExists.MacAddress) {
                        Write-Verbose $localizedData.EnableStaticMacAddress
                        $SetArguments.Add('StaticMacAddress', $StaticMacAddress)
                    }
                } elseif ($NetAdapterExists.SwitchName -ne $SwitchName) {
                    Write-Verbose $localizedData.PerformSwitchConnect
                    Connect-VMNetworkAdapter -VMNetworkAdapter $NetAdapterExists -SwitchName $SwitchName -ErrorAction Stop -Verbose
                }
                
                Write-Verbose $localizedData.PerformVMNetModify
                Set-VMNetworkAdapter @SetArguments -ErrorAction Stop
            } else {
                Write-Verbose $localizedData.CannotChangeHostAdapterMacAddress
            }
        } else {
            if ($VMName -ne 'Management OS') {
                if ($DynamicMacAddress) {
                    $Arguments.Add('DynamicMacAddress',$true)
                } elseif ($StaticMacAddress) {
                    $Arguments.Add('StaticMacAddress',$StaticMacAddress)
                }
                $Arguments.Add('SwitchName',$SwitchName)
            }
            Write-Verbose $localizedData.AddVMNetAdapter
            Add-VMNetworkAdapter @Arguments -ErrorAction Stop
        }
    } else {
        Write-Verbose $localizedData.RemoveVMNetAdapter
        Remove-VMNetworkAdapter @Arguments -ErrorAction Stop
    }
}

Function Test-TargetResource {
	[CmdletBinding()]
	[OutputType([System.Boolean])]
    Param (
        [Parameter(Mandatory)]
        [String] $Id,
                
        [Parameter(Mandatory)]
        [String] $Name,

        [Parameter(Mandatory)]
        [String] $SwitchName,

        [Parameter(Mandatory)]
        [String] $VMName,

        [Parameter()]
        [Bool] $DynamicMacAddress,

        [Parameter()]
        [String] $StaticMacAddress,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String] $Ensure='Present'
    )

    if ($DynamicMacAddress -and $StaticMacAddress) {
        throw $localizedData.StaticAndDynamicTogether
    }

    $Arguments = @{
        Name = $Name
    }

    if ($VMName -ne 'Management OS') {
        $Arguments.Add('VMName',$VMName)
    } else {
        $Arguments.Add('ManagementOS', $true)
        $Arguments.Add('SwitchName', $SwitchName)
    }
    
    Write-Verbose $localizedData.GetVMNetAdapter
    $NetAdapterExists = Get-VMNetworkAdapter @Arguments -ErrorAction SilentlyContinue

    if ($Ensure -eq 'Present') {
        if ($AdapterExists) {
            if ($VMName -ne 'Management OS') {
                if ($DynamicMacAddress) {
                    if ($AdapterExists.DynamicMacAddressEnabled) {
                        Write-Verbose $localizedData.VMNetAdapterExistsNoActionNeeded
                        return $true
                    } else {
                        Write-Verbose $localizedData.EnableDynamicMacAddress
                        return $false
                    }
                } elseif ($StaticMacAddress) {
                    if ($AdapterExists.MacAddress -eq $StaticMacAddress) {
                        Write-Verbose $localizedData.VMNetAdapterExistsNoActionNeeded
                        return $true
                    } else {
                        Write-Verbose $localizedData.EnableStaticMacAddress
                        return $false
                    }
                } elseif ($AdapterExists.SwitchName -ne $SwitchName) {
                    Write-Verbose $localizedData.SwitchIsDifferent
                    return $false
                } 
                else {
                    Write-Verbose $localizedData.VMNetAdapterExistsNoActionNeeded
                    return $true
                }
            } else {
                Write-Verbose $localizedData.VMNetAdapterExistsNoActionNeeded
                return $true
            }
        } else {
            Write-Verbose $localizedData.VMNetAdapterDoesNotExistShouldAdd
            return $false
        }
    } else {
        if ($AdapterExists) {
            Write-Verbose $localizedData.VMNetAdapterExistsShouldRemove
            return $false
        } else {
            Write-Verbose $localizedData.VMNetAdapterDoesNotExistNoActionNeeded
            return $true
        }
    }
}