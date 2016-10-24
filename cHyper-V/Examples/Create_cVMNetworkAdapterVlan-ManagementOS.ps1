Configuration HostOSAdapterVlan
{
    Import-DscResource -ModuleName cHyper-V -Name cVMNetworkAdapterVlan
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    cVMNetworkAdapterVlan HostOSAdapterVlan {
        Name = 'Management-NIC'
        VMName = 'ManagementOS'
        AdapterMode = 'Access'
        VlanId = 10
    }
}