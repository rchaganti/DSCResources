Configuration VMAdapterSettings
{
    Import-DscResource -ModuleName cHyper-V -Name cVMNetworkAdapterSettings
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    cVMNetworkAdapterSettings VMAdapterSettings01 {
        Name = 'Management-NIC'
        VMName = 'DHCPVM01'
        SwitchName = 'SETSwitch'
        DhcpGuard = 'On'
        DeviceNaming = 'On'
    }

    cVMNetworkAdapterSettings VMAdapterSettings02 {
        Name = 'App-NIC'
        VMName = 'DHCPVM01'
        SwitchName = 'SETSwitch'
        DeviceNaming = 'On'
    }
}