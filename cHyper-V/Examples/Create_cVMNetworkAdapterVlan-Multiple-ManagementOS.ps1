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

    cVMNetworkAdapterVlan ClusterAdapterVlan {
        Name = 'Cluster-NIC'
        VMName = 'ManagementOS'
        AdapterMode = 'Access'
        VlanId = 20
    }

    #The following configuration removes any VLAN setting, if present.
    cVMNetworkAdapterVlan JustAnotherAdapterVlan {
        Name = 'JustAnother-NIC'
        VMName = 'ManagementOS'
        AdapterMode = 'Untagged'
    }
}