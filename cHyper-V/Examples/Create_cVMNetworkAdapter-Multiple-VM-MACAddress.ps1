Configuration VMAdapter
{
    Import-DscResource -ModuleName cHyper-V -Name cVMNetworkAdapter
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    cVMNetworkAdapter MyVM01NIC {
        Name = 'MyVM01-NIC'
    	SwitchName = 'SETSwitch'
        MacAddress = '001523be0c'
        VMName = 'MyVM01'
    	Ensure = 'Present'
    }

    cVMNetworkAdapter MyVM02NIC {
        Name = 'MyVM02-NIC'
    	SwitchName = 'SETSwitch'
        MacAddress = '001523be0d'
        VMName = 'MyVM02'
    	Ensure = 'Present'
    }
}