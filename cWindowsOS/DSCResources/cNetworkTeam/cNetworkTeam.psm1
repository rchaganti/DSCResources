# Fallback message strings in en-US
DATA localizedData
{
    # same as culture = "en-US"
ConvertFrom-StringData @'    
    GetTeamInfo=Getting network team information for {0}.
    FoundTeam=Found a network team with name {0}.
    TeamMembersExist=Members in the network team {0} exist as per the configuration.
    TeamNotFound=Network team with name {0} not found.
    LBAlgoDifferent=Load Balancing Algo is different from the requested {0} algo.
    TeamingModeDifferent=Teaming mode is different from the requested {0} mode.
    ModifyTeam=Modifying the network team named {0}.
    MembersDifferent=Members within the team named {0} are different from that requested in the configuration.
    RemovingMembers=Removing members {0} not specified in the configuration.
    AddingMembers=Adding members {0} that are not a part of the team configuration.
    CreateTeam=Creating a network team with the name {0}.
    RemoveTeam=Removing a network team with the name {0}.
    TeamExistsNoAction=Network team with name {0} exists. No action needed.
    TeamExistsWithDifferentConfig=Network team with name {0} exists but with different configuration. This will be modified.
    TeamDoesNotExistShouldCreate=Network team with name {0} does not exist. It will be created.
    TeamExistsShouldRemove=Network team with name {0} exists. It will be removed.
    TeamDoesNotExistNoAction=Network team with name {0} does not exist. No action needed.
    WaitingForTeam=Waiting for network team status to change to up.
    CreatedNetTeam=Network Team was created successfully.
    FailedToCreateTeam=Network team with specific configuration failed to changed to up state within timeout period of 120 seconds.
'@
}

if (Test-Path $PSScriptRoot\en-us)
{
    Import-LocalizedData LocalizedData -filename cNetworkTeam.psd1
}

Function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])] 
    Param
    (
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [String[]]$TeamMembers
    )
    
    $Configuration = @{
        Name = $Name
        TeamMembers = $TeamMembers
    }

    Write-Verbose ($localizedData.GetTeamInfo -f $Name)
    $NetworkTeam = Get-NetLBFOTeam -Name $Name -ErrorAction SilentlyContinue

    if ($NetworkTeam) {
        Write-Verbose ($localizedData.FoundTeam -f $Name)
        if ((Compare-Object $TeamMembers $NetworkTeam.Members) -eq $null) {
            Write-Verbose ($localizedData.TeamMembersExist -f $Name)
            $Configuration.Add('LoadBalancingAlgorithm', $NetworkTeam.LoadBalancingAlgorithm)
            $Configuration.Add('TeamingMode', $NetworkTeam.TeamingMode)
            $Configuration.Add('Ensure','Present')
        }
    } else {
        Write-Verbose ($localizedData.TeamNotFound -f $Name)
        $Configuration.Add('Ensure','Absent')
    }
    $Configuration
}

Function Set-TargetResource 
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [String[]]$TeamMembers,
    
        [Parameter()]
        [ValidateSet("SwitchIndependent", "LACP", "Static")]
        [String]$TeamingMode = "SwitchIndependent",

        [Parameter()]
        [ValidateSet("Dynamic", "HyperVPort", "IPAddresses", "MacAddresses", "TransportPorts")]
        [String]$LoadBalancingAlgorithm = "HyperVPort",

        [ValidateSet('Present', 'Absent')]
        [String]$Ensure = 'Present'
    )
    Write-Verbose ($localizedData.GetTeamInfo -f $Name)
    $NetworkTeam = Get-NetLBFOTeam -Name $Name -ErrorAction SilentlyContinue

    if ($Ensure -eq 'Present') {
        if ($NetworkTeam) {
            Write-Verbose ($localizedData.FoundTeam -f $Name)
            $SetArguments = @{
                'Name' = $Name
            }

            if ($NetworkTeam.LoadBalancingAlgorithm -ne $LoadBalancingAlgorithm) {
                Write-Verbose ($localizedData.LBAlgoDifferent -f $LoadBalancingAlgorithm)
                $SetArguments.Add('LoadBalancingAlgorithm', $LoadBalancingAlgorithm)
                $IsNetModifyRequired = $true
            }

            if ($NetworkTeam.TeamingMode -ne $TeamingMode) {
                Write-Verbose ($localizedData.TeamingModeDifferent -f $TeamingMode)
                $SetArguments.Add('TeamingMode', $TeamingMode)
                $IsNetModifyRequired = $true
            }
            
            if ($IsNetModifyRequired) {
                Write-Verbose ($localizedData.ModifyTeam -f $Name)
                Set-NetLbfoTeam @SetArguments -ErrorAction Stop -Confirm:$false
            }

            $NetTeamMembers = Compare-Object -ReferenceObject $TeamMembers -DifferenceObject $NetworkTeam.Members
            if ($NetTeamMembers -ne $null) {
                Write-Verbose ($localizedData.MembersDifferent -f $Name)
                $MembersToRemove = ($NetTeamMembers | Where-Object {$_.SideIndicator -eq '=>'}).InputObject
                if ($MembersToRemove) {
                    Write-Verbose ($localizedData.RemovingMembers -f ($MembersToRemove -join ','))
                    $null = Remove-NetLbfoTeamMember -Name $MembersToRemove -Team $Name -ErrorAction Stop -Confirm:$false
                }

                $MembersToAdd = ($NetTeamMembers | Where-Object {$_.SideIndicator -eq '<='}).InputObject
                if ($MembersToAdd) {
                    Write-Verbose ($localizedData.AddingMembers -f ($MembersToAdd -join ','))
                    $null = Add-NetLbfoTeamMember -Name $MembersToAdd -Team $Name -ErrorAction Stop -Confirm:$false
                }
            }
            
        } else {
            Write-Verbose ($localizedData.CreateTeam -f $Name)
            $null = New-NetLbfoTeam -Name $Name -TeamMembers $TeamMembers -TeamingMode $TeamingMode -LoadBalancingAlgorithm $LoadBalancingAlgorithm -ErrorAction Stop -Confirm:$false
            $timeout = 0
            While ((Get-NetLbfoTeam -Name $Name).Status -ne 'Up'){
                Write-Verbose $localizedData.WaitingForTeam
                if ($timeout -ge 120) {
                    throw $localizedData.FailedToCreateTeam   
                }
                Start-Sleep -Seconds 2
                $timeout += 2
            }

            if ((Get-NetLbfoTeam -Name $Name).Status -eq 'Up') {
                Write-Verbose $localizedData.CreatedNetTeam
            }
        }
    } else {
        Write-Verbose ($localizedData.RemoveTeam -f $Name)
        $null = Remove-NetLbfoTeam -Name $Name -ErrorAction Stop -Confirm:$false
    }
}

Function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
    Param
    (
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [String[]]$TeamMembers,
    
        [Parameter()]
        [ValidateSet("SwitchIndependent", "LACP", "Static")]
        [String]$TeamingMode = "SwitchIndependent",

        [Parameter()]
        [ValidateSet("Dynamic", "HyperVPort", "IPAddresses", "MacAddresses", "TransportPorts")]
        [String]$LoadBalancingAlgorithm = "HyperVPort",

        [ValidateSet('Present', 'Absent')]
        [String]$Ensure = 'Present'
    )
    
    Write-Verbose ($localizedData.GetTeamInfo -f $Name)
    $NetworkTeam = Get-NetLBFOTeam -Name $Name -ErrorAction SilentlyContinue
    
    if ($Ensure -eq 'Present') {
        if ($NetworkTeam) {
            Write-Verbose ($localizedData.FoundTeam -f $Name)
            if (($NetworkTeam.LoadBalancingAlgorithm -eq $LoadBalancingAlgorithm) -and ($NetworkTeam.TeamingMode -eq $TeamingMode) -and ((Compare-Object -ReferenceObject $TeamMembers -DifferenceObject $NetworkTeam.Members) -eq $null)) {
                Write-Verbose ($localizedData.TeamExistsNoAction -f $Name)
                return $true
            } else {
                Write-Verbose ($localizedData.TeamExistsWithDifferentConfig -f $Name)
                return $false
            }
        } else {
            Write-Verbose ($localizedData.TeamDoesNotExistShouldCreate -f $Name)
            return $false
        }
    } else {
        if ($NetworkTeam) {
            Write-Verbose ($localizedData.TeamExistsShouldRemove -f $Name)
            return $false
        } else {
            Write-Verbose ($localizedData.TeamDoesNotExistNoAction -f $Name)
            return $true
        }
    }
}