Configuration HostOSAdapter
{
    Import-DscResource -ModuleName cHyper-V -Name cVMNetworkAdapter
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    cVMNetworkAdapter HostOSAdapter {
        Name = 'Management-NIC'
    	SwitchName = 'SETSwitch'
        VMName = 'ManagementOS'
    	Ensure = 'Present'
    }
}