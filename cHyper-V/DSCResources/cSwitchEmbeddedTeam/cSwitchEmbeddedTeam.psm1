# Fallback message strings in en-US
DATA localizedData
{
    # same as culture = "en-US"
ConvertFrom-StringData @'    
    PacketDirectMustUseHyperVPort=Using Enable Packet Redirect on the SET team must use Hyper-V Port mode as the load balancing algorightm. This will reset the LB mode.
    NoHyperVModule=Hyper-V PowerShell Module not found.
    CheckSETMembers=Checking if SET network adapter members match or not.
    TeamMembersUpdate=SET Network Adapter members mismatch. This will be updated.
    LBUpdate=SET load balancing mode is different. It will be updated.
    TeamingModeUpdate=SET teaming mode is differet. It will be updated.
    UpdatingSETeam=Updating SET configuration as requested.
    UpdateAllowManagementOS=Updating AllowManagementOS on the VM switch associated with the SET.
    IOVcannotbeUpdated=EnableIOV cannot be updated once SET is created. Ignoring this change in configuration.
    ReservationModeCannotBeUpdated=Reservation mode cannot be updated once SET is created. Ignoring this change in configuration.
    PacketDirectCannotBeUpdated=Packet Direct cannot be updated once SET is created. Ignoring this change in configuration.
    CheckNetAdapter=Checking if network adapter specified is a part of another VM switch.
    SwitchWithNameExists=Another switch with specified name already exists. It is not recommeded to use the same name for mulitple switches.
    UsedAdapter=One of the adapters in the specified SET configuration is being used in another switch.
    CreateSET=Creating SwitchEmbeddedTeam.
    UpdateSET=Updating SwitchEmbeddedTeam.
    RemoveSET=Removing SwitchEmbeddedTeam.
    CheckSwitchExists=Checking if SET already exists.
    SETMembersDontMatch=SET members don't match. This team will be updated.
    CheckSETIOV=Checking if IOV is enabled.
    CheckSETReservationMode=Checking if reservation mode is configured as desired.
    CheckSETEnablePacketDirect=Checking if packet direct is enabled.
    CheckSETLoadBalacing=Checking if load balancing mode is configured as desired.
    CheckSETTeamingMode=Checking if SET teaming mode is configured as desired.
    SwitchConfigPresentNoAction=Switch configuration present as desired. No action needed.
    SwitchPresentRemove=Switch team is present while it should not. It will be removed.
    SwitchNotPresentCreate=Switch team does not exist. It will be created.
    SwitchNotPresentNoAction=Switch team exists. No action needed.
    SwitchNotPresent=Switch is not present.
    CheckSETAllowManagementOS=Checking if AllowManagementOS configurtion is present.
'@
}

if (Test-Path "$PSScriptRoot\$PSCulture")
{
    Import-LocalizedData LocalizedData -filename "cSwitchEmbeddedTeam.psd1" -BaseDirectory "$PSScriptRoot\$PSCulture"
}

function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory)]
		[String]$Name,

		[parameter()]
		[String[]]$NetAdapterName
	)

    # Check if Hyper-V module is present for Hyper-V cmdlets
    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw $localizedData.NoHyperVModule
    }

    $SwitchTeam = Get-VMSwitchTeam -Name $Name -ErrorAction SilentlyContinue
    $Switch = Get-VMSwitch -Name $Name -ErrorAction SilentlyContinue

    $SwitchAdapter = ((Get-NetAdapter).Where({$switchTeam.NetAdapterInterfaceDescription -contains $_.InterfaceDescription})).Name

    @{
		Name              = $SwitchTeam.Name
		NetAdapterName    = $SwitchAdapter
		AllowManagementOS = $switch.AllowManagementOS
        EnablePacketDirect = $Switch.PacketDirectEnabled
        EnableIov = $switch.IovEnabled
        BandwidthReservationMode = $switch.BandwidthReservationMode
        TeamingMode = $SwitchTeam.TeamingMode
        LoadBalancingAlgorithm = $SwitchTeam.LoadBalancingAlgorithm
	}
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory)]
		[String]$Name,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateCount(1,8)]
		[String[]]$NetAdapterName,

		[Parameter()]
        [Boolean]$AllowManagementOS,

		[Parameter()]
        [Boolean]$EnableIov,

		[Parameter()]
        [Boolean]$EnablePacketDirect,

		[parameter()]
        [ValidateSet('SwitchIndependent')]
		[String]$TeamingMode='SwitchIndependent',

		[parameter()]
		[ValidateSet('Dynamic','HyperVPort')]
        [String]$LoadBalancingAlgorithm='Dynamic',

        [Parameter()]
        [ValidateSet('None', 'Default', 'Weight', 'Absolute')]
        [String] $BandwidthReservationMode,

		[ValidateSet("Present","Absent")]
		[String]$Ensure = "Present"
	)

    # Check if Hyper-V module is present for Hyper-V cmdlets
    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw $localizedData.NoHyperVModule
    }

    if($Ensure -eq 'Present')
    {
        $switchTeam = (Get-VMSwitchTeam -Name $Name -ErrorAction SilentlyContinue)
        if($switchTeam)
        {
            $switch = Get-VMSwitch -Name $Name -ErrorAction SilentlyContinue
            
            Write-Verbose $localizedData.CheckSETMembers
            $SwitchAdapter = ((Get-NetAdapter).Where({$switchTeam.NetAdapterInterfaceDescription -contains $_.InterfaceDescription})).Name
            $SwitchTeamMembers = Compare-Object -ReferenceObject $NetAdapterName -DifferenceObject $SwitchAdapter
            
            $TeamParameters = @{
                Name = $name
            }
            
            if($SwitchTeamMembers -ne $null)
            {
                $TeamParameters.Add('NetAdapterName',$NetAdapterName)
                $UpdateTeam = $true
                Write-Verbose $localizedData.TeamMembersUpdate
            }

            if ($switchTeam.LoadBalancingAlgorithm -ne $LoadBalancingAlgorithm) {
                $TeamParameters.Add('LoadBalancingAlgorithm',$LoadBalancingAlgorithm)
                Write-Verbose $localizedData.LBUpdate
                $UpdateTeam = $true
            }

            if ($switchTeam.TeamingMode -ne $TeamingMode) {
                $TeamParameters.Add('TeamingMode', $TeamingMode)
                Write-Verbose $localizedData.TeamingModeUpdate
                $UpdateTeam = $true
            }

            if ($UpdateTeam) {
                Write-Verbose $localizedData.UpdatingSETeam
                Set-VMSwitchTeam @TeamParameters -Verbose
            }
            
            if ($switch.AllowManagementOS -ne $AllowManagementOS) {
                Write-Verbose $localizedData.UpdateAllowManagementOS
                $switch | Set-VMSwitch -AllowManagementOS $AllowManagementOS -Verbose
            }

            if ($switch.IovEnabled -ne $EnableIov) {
                Write-Warning $localizedData.IOVcannotbeUpdated  
            } elseif ($BandwidthReservationMode -and ($switch.BandwidthReservationMode -ne $BandwidthReservationMode)) {
                Write-Warning $locallizedData.ReservationModeCannotBeUpdated  
            }

            if ($switch.PacketDirectEnabled -ne $EnablePacketDirect) {
                Write-Warning $localizedData.PacketDirectCannotBeUpdated
            }
        } else {
            Write-Verbose -Message $localizedData.CheckNetAdapter
            $VMSwitchArray = Get-VMSwitch
            Foreach ($vmSwitch in $VMSwitchArray) {
                if ($vmSwitch.Name -eq $Name) {
                    Write-Warning $localizedData.SwitchWithNameExists
                }

                $SwitchAdapter = ((Get-NetAdapter).Where({$vmSwitch.NetAdapterInterfaceDescriptions -contains $_.InterfaceDescription})).Name
                $UsedAdapter = ((Compare-Object $SwitchAdapter $NetAdapterName -IncludeEqual).Where({$_.SideIndicator -eq '=='})).InputObject
                if ($UsedAdapter) {
                    Throw $localizedData.UsedAdapter
                }
            }
            
            $parameters = @{
                Name = $Name
                NetAdapterName = $NetAdapterName
                AllowManagementOS = $AllowManagementOS
                EnablePacketDirect = $EnablePacketDirect
            }
            
            if ($EnablePacketDirect -and ($LoadBalancingAlgorithm -ne 'HyperVPort')) {
                Write-Warning $localizedData.PacketDirectMustUseHyperVPort
                $LoadBalancingAlgorithm = 'HyperVPort'
            }

            if ($NetAdapterName.Length -eq 1) {
                $parameters.Add('EnableEmbeddedTeaming',$true)
            }
            
            if ($EnableIov) {
                $parameters.Add('EnableIov',$true)
            } elseif($BandwidthReservationMode) {
                $parameters.Add('MinimumBandwidthMode',$BandwidthReservationMode)
            }

            Write-Verbose $localizedData.CreateSET
            $null = New-VMSwitch @parameters -ErrorAction Stop

            Write-Verbose $localizedData.UpdateSET
            $null = Set-VMSwitchTeam -Name $Name -TeamingMode $TeamingMode -LoadBalancingAlgorithm $LoadBalancingAlgorithm -ErrorAction Stop
        }
    }
    # Ensure is set to "Absent", remove the switch
    else
    {
        Write-Verbose $localizedData.RemoveSET
        Get-VMSwitch $Name -ErrorAction SilentlyContinue | Remove-VMSwitch -Force -ErrorAction Stop
    }
}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory)]
		[String]$Name,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateCount(1,8)]
		[String[]]$NetAdapterName,

		[Parameter()]
        [Boolean]$AllowManagementOS,

		[Parameter()]
        [Boolean]$EnableIov,

		[Parameter()]
        [Boolean]$EnablePacketDirect,

		[parameter()]
        [ValidateSet('SwitchIndependent')]
		[String]$TeamingMode='SwitchIndependent',

		[parameter()]
		[ValidateSet('Dynamic','HyperVPort')]
        [String]$LoadBalancingAlgorithm='Dynamic',

        [Parameter()]
        [ValidateSet('None', 'Default', 'Weight', 'Absolute')]
        [String] $BandwidthReservationMode,

		[ValidateSet("Present","Absent")]
		[String]$Ensure = "Present"
	)

    # Check if Hyper-V module is present for Hyper-V cmdlets
    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw $localizedData.NoHyperVModule
    }

    try
    {
        # Check if switch exists
        Write-Verbose $localizedData.CheckSwitchExists
        $switchTeam = Get-VMSwitchTeam -Name $Name -ErrorAction Stop

        # If SET exists
        if($switchTeam)
        {
            $Switch = Get-VMSwitch -Name $Name
            if($Ensure -eq 'Present')
            {
                Write-Verbose $localizedData.CheckSETMembers
                $SwitchAdapter = ((Get-NetAdapter).Where({$switchTeam.NetAdapterInterfaceDescription -contains $_.InterfaceDescription})).Name
                $SwitchTeamMembers = Compare-Object -ReferenceObject $NetAdapterName -DifferenceObject $SwitchAdapter
                if($SwitchTeamMembers -ne $null)
                {
                    Write-Verbose $localizedData.SETMembersDontMatch
                    return $false
                }
                 
                if($PSBoundParameters.ContainsKey("AllowManagementOS"))
                {
                    Write-Verbose $localizedData.CheckSETAllowManagementOS
                    if(($switch.AllowManagementOS -ne $AllowManagementOS))
                    {
                        Write-Verbose $localizedData.UpdateAllowManagementOS    
                        return $false
                    }
                }

                if ($EnableIov) {
                    Write-Verbose $localizedData.CheckSETIOV
                    if (-not $switch.IovEnabled) {
                        Write-Warning $localizedData.IOVcannotbeUpdated

                        #We cannot update this configuration once switch is created unless we destroy and re-create. Destroying is a good option. So, don't return false.
                        return $true    
                    }
                } else {
                    Write-Verbose $localizedData.CheckSETReservationMode
                    if ($BandwidthReservationMode -and ($BandwidthReservationMode -ne $switch.BandwidthReservationMode)) {
                        Write-Warning $localizedData.ReservationModeCannotBeUpdated
                        return $true
                    }
                }

                if ($EnablePacketDirect) {
                    Write-Verbose $localizedData.CheckSETEnablePacketDirect
                    if (-not $switch.EnablePacketDirect) {
                        Write-Warning $localizedData.PacketDirectCannotBeUpdated
                        #We cannot update this configuration once switch is created unless we destroy and re-create. Destroying is a good option. So, don't return false.
                        return $true
                    }                    
                }

                Write-Verbose $localizedData.CheckSETLoadBalacing
                if ($switchTeam.LoadBalancingAlgorithm -ne $LoadBalancingAlgorithm) {
                    return $false
                }
                
                Write-Verbose $localizedData.CheckSETTeamingMode
                if ($switchTeam.TeamingMode -ne $TeamingMode) {
                    return $false
                }

                Write-Verbose $localizedData.SwitchConfigPresentNoAction
                return $true
            }
            # If switch should be absent, but is there, return $false
            else
            {
                Write-Verbose $localizedData.SwitchPresentRemove
                return $false
            }
        } else {
            if ($Ensure -eq 'Present') {
                Write-Verbose $localizedData.SwitchNotPresentCreate
                return $false
            } else {
                Write-Verbose $localizedData.SwitchNotPresentNoAction
                return $true
            }
        }
    }

    catch [System.Management.Automation.ActionPreferenceStopException]
    {
        Write-Verbose $localizedData.SwitchNotPresent
        return $false
    }
}

Export-ModuleMember -Function *-TargetResource