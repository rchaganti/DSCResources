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
    PerformVMNetModify=Performing VM Network Adapter configuration changes.
    VMNetAdapterExistsNoActionNeeded=VM Network Adapter exists with requested configuration. No action needed.
    VMNetAdapterDoesNotExist=VM Network adapter does not exist.
    VMNetAdapterExistsWithDifferentConfiguration=VM Network Adapter exists but different configuration. This will be fixed.
'@
}

if (Test-Path $PSScriptRoot\en-us)
{
    Import-LocalizedData LocalizedData -filename cVMNetworkAdapterSettings.psd1
}

Function Get-TargetResource {
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
    Param (
        [Parameter(Mandatory)]
        [String] $Name,

        [Parameter(Mandatory)]
        [String] $SwitchName,

        [Parameter(Mandatory)]
        [Bool] $ManagementOS,

        [Parameter()]
        [String] $VMName
    )

    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw $localizedData.HyperVModuleNotFound
    }

    $Configuration = @{
        Name = $Name
        SwitchName = $SwitchName
    }

    if ($ManagementOS -and $VMName) {
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
        $Arguments.Add('ManagementOS',$true)
        $Arguments.Add('SwitchName', $SwitchName)
    }

    Write-Verbose $localizedData.GetVMNetAdapter
    $NetAdapter = Get-VMNetworkAdapter @Arguments -ErrorAction SilentlyContinue

    if ($NetAdapter) {
        Write-Verbose $localizedData.FoundVMNetAdapter
        $Configuration.Add('MacAddressSpoofing', $NetAdapter.MacAddressSpoofing)
        $Configuration.Add('DhcpGuard', $NetAdapter.DhcpGuard)
        $Configuration.Add('RouterGuard', $NetAdapter.RouterGuard)
        $Configuration.Add('AllowTeaming', $NetAdapter.AllowTeaming)
        $Configuration.Add('VmqWeight', $NetAdapter.VmqWeight)
        $Configuration.Add('MaximumBandwidth',$NetAdapter.BandwidthSetting.MaximumBandwidth)
        $Configuration.Add('MinimumBandwidthWeight',$NetAdapter.BandwidthSetting.MinimumBandwidthWeight)
        $Configuration.Add('MinimumBandwidthAbsolute',$NetAdapter.BandwidthSetting.MinimumBandwidthAbsolute)
        $Configuration.Add('IeeePriorityTag',$NetAdapter.IeeePriorityTag)
        $Configuration.Add('PortMirroring',$NetAdapter.PortMirroringMode)
    } else {
        Write-Verbose $localizedData.NoVMNetAdapterFound
    }

    $Configuration
}

Function Set-TargetResource {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]
        [String] $Name,

        [Parameter(Mandatory)]
        [String] $SwitchName,

        [Parameter(Mandatory)]
        [Bool] $ManagementOS,

        [Parameter()]
        [String] $VMName,

        [Parameter()]
        [ValidateSet('On','Off')]
        [String] $MacAddressSpoofing = 'Off',

        [Parameter()]
        [ValidateSet('On','Off')]
        [String] $DhcpGuard = 'Off',

        [Parameter()]
        [ValidateSet('On','Off')]
        [String] $IeeePriorityTag = 'Off',

        [Parameter()]
        [ValidateSet('On','Off')]
        [String] $RouterGuard = 'Off',

        [Parameter()]
        [ValidateSet('On','Off')]
        [String] $AllowTeaming = 'Off',

        [Parameter()]
        [uint64] $MaximumBandwidth = 0,

        [Parameter()]
        [ValidateRange(0,100)]
        [uint32] $MinimumBandwidthWeight = 0,

        [Parameter()]
        [uint32] $MinimumBandwidthAbsolute,
        
        [Parameter()]
        [ValidateRange(0,100)]
        [uint32] $VmqWeight = 100,        

        [Parameter()]
        [ValidateSet('None','Source','Destination')]
        [String] $PortMirroring = 'None'
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
        $Arguments.Add('SwitchName', $SwitchName)
    }
    
    Write-Verbose $localizedData.GetVMNetAdapter
    $NetAdapter = Get-VMNetworkAdapter @Arguments -ErrorAction SilentlyContinue

    $SetArguments = @{
        VMNetworkAdapter = $NetAdapter
        MacAddressSpoofing = $MacAddressSpoofing
        DhcpGuard = $DhcpGuard
        RouterGuard = $RouterGuard
        VmqWeight = $VmqWeight
        MaximumBandwidth = $MaximumBandwidth
        MinimumBandwidthWeight = $MinimumBandwidthWeight
        MinimumBandwidthAbsolute= $MinimumBandwidthAbsolute
        IeeePriorityTag = $IeeePriorityTag
        AllowTeaming = $AllowTeaming
        PortMirroring = $PortMirroring
    }
    
    Write-Verbose $localizedData.PerformVMNetModify
    Set-VMNetworkAdapter @SetArguments -ErrorAction Stop
}

Function Test-TargetResource {
	[CmdletBinding()]
	[OutputType([System.Boolean])]
    Param (
        [Parameter(Mandatory)]
        [String] $Name,

        [Parameter(Mandatory)]
        [String] $SwitchName,

        [Parameter(Mandatory)]
        [Bool] $ManagementOS,

        [Parameter()]
        [String] $VMName,

        [Parameter()]
        [ValidateSet('On','Off')]
        [String] $MacAddressSpoofing = 'Off',

        [Parameter()]
        [ValidateSet('On','Off')]
        [String] $DhcpGuard = 'Off',

        [Parameter()]
        [ValidateSet('On','Off')]
        [String] $IeeePriorityTag = 'Off',

        [Parameter()]
        [ValidateSet('On','Off')]
        [String] $RouterGuard = 'Off',

        [Parameter()]
        [ValidateSet('On','Off')]
        [String] $AllowTeaming = 'Off',

        [Parameter()]
        [uint64] $MaximumBandwidth = 0,

        [Parameter()]
        [ValidateRange(0,100)]
        [uint32] $MinimumBandwidthWeight = 0,

        [Parameter()]
        [uint32] $MinimumBandwidthAbsolute,
        
        [Parameter()]
        [ValidateRange(0,100)]
        [uint32] $VmqWeight = 100,        

        [Parameter()]
        [ValidateSet('None','Source','Destination')]
        [String] $PortMirroring = 'None'
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
        $Arguments.Add('SwitchName', $SwitchName)
    }
    
    Write-Verbose $localizedData.GetVMNetAdapter
    $AdapterExists = Get-VMNetworkAdapter @Arguments -ErrorAction SilentlyContinue
    
    if ($AdapterExists) {
        Write-Verbose $localizedData.FoundVMNetAdapter
        if ($AdapterExists.MacAddressSpoofing -eq $MacAddressSpoofing `
            -and $AdapterExists.RouterGuard -eq $RouterGuard `
            -and $AdapterExists.DhcpGuard -eq $DhcpGuard `
            -and $AdapterExists.IeeePriorityTag -eq $IeeePriorityTag `
            -and $AdapterExists.AllowTeaming -eq $AllowTeaming `
            -and $AdapterExists.BandwidthSetting.MaximumBandwidth -eq $MaximumBandwidth `
            -and $AdapterExists.BandwidthSetting.MinimumBandwidthWeight -eq $MinimumBandwidthWeight `
            -and $AdapterExists.BandwidthSetting.MinimumBandwidthAbsolute -eq $MinimumBandwidthAbsolute `
            -and $AdapterExists.VMQWeight -eq $VMQWeight `
            -and $AdapterExists.PortMirroringMode -eq $PortMirroring
        ) {
            Write-Verbose $localizedData.VMNetAdapterExistsNoActionNeeded
            return $true
        } else {
            Write-Verbose $localizedData.VMNetAdapterExistsWithDifferentConfiguration
            return $false
        }
    } else {
        throw $localizedData.VMNetAdapterDoesNotExist
    }
}