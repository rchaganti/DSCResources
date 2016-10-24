Configuration HostOSAdapter
{
    Import-DscResource -ModuleName cHyper-V -Name cVMNetworkAdapter
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    cVMNetworkAdapter ManagementAdapter {
        Name = 'Management-NIC'
    	SwitchName = 'SETSwitch'
        VMName = 'ManagementOS'
    	Ensure = 'Present'
    }

    cVMNetworkAdapter ClusterAdapter {
        Name = 'Cluster-NIC'
    	SwitchName = 'SETSwitch'
        VMName = 'ManagementOS'
    	Ensure = 'Present'
    }
}