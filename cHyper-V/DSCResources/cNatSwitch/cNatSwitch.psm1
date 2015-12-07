# Fallback message strings in en-US
DATA localizedData
{
    # same as culture = "en-US"
ConvertFrom-StringData @'    
    NoHyperVModule=Hyper-V PowerShell Module not found.
    SwitchWithNameExists=Another switch with specified name already exists. It is not recommeded to use the same name for mulitple switches.
    CheckSwitchExists=Checking if NAT Switch already exists.
    SwitchConfigPresentNoAction=NAT Switch configuration present as desired. No action needed.
    SwitchConfigNotPresent=VM Switch is avaialble but not the net NAT configuration. It will be created.
    SwitchPresentRemove=NAT Switch is present while it should not. It will be removed.
    SwitchNotPresentCreate=NAT Switch does not exist. It will be created.
    SwitchNotPresentNoAction=NAT Switch exists. No action needed.
    SwitchNotPresent=NAT Switch is not present.
    SwitchPresent=NAT Switch is present.
    CheckNetNat=Checking if there is an existing Net NAT configuration that matches the VM switch.
    CreateNetNat=Creating Net Nat configuration to match with the VM switch.
    CreateVMSwitch=Creating VM switch with requested configuration.
    RemoveVMSwitch=Removing NAT VM Switch.
'@
}

if (Test-Path "$PSScriptRoot\$PSCulture")
{
    Import-LocalizedData LocalizedData -filename "cNatSwitch.psd1" -BaseDirectory "$PSScriptRoot\$PSCulture"
}

function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory)]
		[String]$Name,

		[parameter(Mandatory)]
		[String]$NATSubnetAddress
	)

    # Check if Hyper-V module is present for Hyper-V cmdlets
    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw $localizedData.NoHyperVModule
    }

    Write-Verbose $localizedData.CheckSwitchExists
    $Switch = (Get-VMSwitch -Name $Name -SwitchType NAT -ErrorAction SilentlyContinue).Where({$_.NATSubnetAddress -eq $NATSubnetAddress})

    $configuration = @{
        Name = $Name
        NatSubnetAddress = $NATSubnetAddress
    }

    if ($switch) {
        $configuration.Add('Ensure','Present')
	}

    $configuration
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory)]
		[String]$Name,

		[parameter(Mandatory)]
		[String]$NATSubnetAddress,

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
        Write-Verbose $localizedData.CheckSwitchExists
        $Switch = (Get-VMSwitch -Name $Name -SwitchType NAT -ErrorAction SilentlyContinue).Where({$_.NATSubnetAddress -eq $NATSubnetAddress})
        if($Switch)
        {         
            Write-Verbose $localizedData.SwitchPresent
            Write-Verbose $localizedData.CheckNetNat
            $NetNat = (Get-NetNat -Name $Name).Where({$_.InternalIPInterfaceAddressPrefix -eq $NATSubnetAddress})
            if (-not $NetNat) {
                Write-Verbose $localizedData.CreateNetNat
                $NetNat = New-NetNat -Name $Name -InternalIPInterfaceAddressPrefix $NATSubnetAddress -Verbose
            }
        } else {
            try {
                Write-Verbose $localizedData.CreateVMSwitch
                $VmSwitch = New-VMSwitch -SwitchType NAT -Name $Name -NATSubnetAddress $NATSubnetAddress -Verbose
                
                Write-Verbose $localizedData.CreateNetNat
                $NetNat = New-NetNat -Name $Name -InternalIPInterfaceAddressPrefix $NATSubnetAddress -Verbose
            }

            catch {
                Write-Error $_
            }
        }
    }
    else
    {
        Write-Verbose $localizedData.RemoveVMSwitch
        $VmSwitch = Get-VMSwitch -Name $Name -SwitchType NAT | Where-Object { $_.NATSubnetAddress -eq $NATSubnetAddress }
        Remove-VMSwitch -VMSwitch $VmSwitch -Verbose
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

		[parameter(Mandatory)]
		[String]$NATSubnetAddress,

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
        Write-Verbose $localizedData.CheckSwitchExists
        $Switch = (Get-VMSwitch -Name $Name -SwitchType NAT -ErrorAction SilentlyContinue).Where({$_.NATSubnetAddress -eq $NATSubnetAddress})

        if($Switch)
        {
            Write-Verbose $localizedData.SwitchPresent
            if($Ensure -eq 'Present')
            {
                Write-Verbose $localizedData.CheckNetNat
                $NetNat = (Get-NetNat -Name $Name).Where({$_.InternalIPInterfaceAddressPrefix -eq $NATSubnetAddress})
                if (-not $NetNat) {
                    Write-Verbose $localizedData.SwitchConfigNotPresent
                    return $false
                }
                else
                {
                    Write-Verbose $localizedData.SwitchConfigPresentNoAction
                    return $true
                }
            }
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