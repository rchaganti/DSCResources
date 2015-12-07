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