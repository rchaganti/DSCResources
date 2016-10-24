Configuration VMIPAddress
{
    Import-DscResource -ModuleName cHyper-V -Name cVMIPAddress
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    cVMIPAddress VMAdapter1IPAddress {
        NetAdapterName = 'VMMgmt-NIC'
        VMName = 'SQLVM01'
        IPAddress = 'DHCP'
    }
}