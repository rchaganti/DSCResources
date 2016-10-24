Configuration VMAdapterSettings
{
    Import-DscResource -ModuleName cHyper-V -Name cVMNetworkAdapterSettings
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    cVMNetworkAdapterSettings VMAdapterSettings {
        Name = 'Management-NIC'
        VMName = 'DHCPVM01'
        SwitchName = 'SETSwitch'
        DhcpGuard = 'On'
    }
}