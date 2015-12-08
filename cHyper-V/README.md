# DSCResources #
### Custom DSC resource module for Microsoft Hyper-V Networking by [PowerShell Magazine](http://www.powershellmagazine.com "PowerShell Magazine"). ###

----------
Microsoft Hyper-V DSC resource module contains a set of resources for managing Hyper-V management OS and guest networking.

- [cVMSwitch](https://github.com/rchaganti/DSCResources/tree/master/cHyper-V/DSCResources/cVMSwitch) is used to create virtual machine switches.
- [cSwitchEmbeddedTeam](https://github.com/rchaganti/DSCResources/tree/master/cHyper-V/DSCResources/cSwitchEmbeddedTeam) is used to create switch embedded team VM switches on Server 2014 TP4 and above.
- [cNatSwitch](https://github.com/rchaganti/DSCResources/tree/master/cHyper-V/DSCResources/cNatSwitch) is used to deploy a VM switch of NAT type.
- [cVMNetworkAdapter](https://github.com/rchaganti/DSCResources/tree/master/cHyper-V/DSCResources/cVMNetworkAdapter) is used to create VM network adapters to attach to either management OS or the virtual machines.
- [cVMNetworkAdapterSettings](https://github.com/rchaganti/DSCResources/tree/master/cHyper-V/DSCResources/cVMNetworkAdapterSettings) is used to configure VM network adapter settings such as bandwidth weights, port mirroring, DHCP guard, MAC address spoofing, etc.
- [cVMNetworkAdapterVlan](https://github.com/rchaganti/DSCResources/tree/master/cHyper-V/DSCResources/cVMNetworkAdapterVlan) is used to configure VLANs on virtual network adapters either in the management OS or virtual machines.

Note that before using any of the custom resources, you must either import the individual resources or the entire module containing these resources. You can do this using the Import-DscResource cmdlet.

####Using cVMSwitch resource####
This resource module is a fork from Microsoft's xHyper-V resource module. I have added the capability to manage bandwidth settings of the VM switch. Therefore, using this resource you can create and manage hyper-V VM switches.

![](http://i.imgur.com/DVm78Eq.png)

When using this DSC resource, the *Name* and *Type* are mandatory properties where *Name* is the unique key properties. The *AllowManagementOS* property can be used to add a VM network adapter attached to the VM switch we are creating in the management OS. The *EnableIoV* property lets us enable SR-IOV capability on the VM switch. The *MinimumBandwidthMode* and *EnableIoV* properties are mutually exclusive. We cannot configure both at the same time. The *MinimumBandwidthMode* property can be used to configure a converged network switch on Hyper-V. The *NetAdapterName* parameter is used when creating a VM switch of *External* type.

Here is an example of how you use this DSC resource.

    cVMSwitch HostSwitch {
    	Name = 'HostSwitch'
    	Type = 'External'
    	AllowManagementOS = $true
    	MinimumBandwidthMode = 'Weight'
    	NetAdapterName = 'HostTeam'
    	Ensure = 'Present'
    }

####Using cSwitchEmbeddedTeam resource####
This DSC resource works only from Windows Server 2016 TP4 onwards. This can be used to create Switch Embedded Team used in Windows Server 2016 Hyper-V. 

![](http://i.imgur.com/cDsOi2S.png)

Similar to the cVMSwitch resource, the *Name* property is the unique key property. The *AllowManagementOS* property when set to *$true*, will attach a VM network adapter automatically with the same name as the SET to the management OS. The *EnableIoV* and the *BandwidthReservationMode* properties are mutually exclusive. *BandwidthReservationMode* property is same as *MinimumBandwidthMode* in the cVMSwitch DSC resource.

At the time of writing this resource module, SET supports only *SwitchIndepedent* load balancing algorithm. The *TeamingMode* can be set of either *HyperVPort* or *Dynamic*. The default is *Dynamic*. The *NetAdapterName* property can be used to specify the members of the SET. You can specify a comma-separated list of physical network adapters.

Here is how you use this resource.

    cSwitchEmbeddedTeam DemoSETteam {
        Name = 'MySetTeam'
        NetAdapterName = 'NIC1','NIC2'
        AllowManagementOS = $true
        Ensure = 'Present' 
    }

####Using cNatSwitch resource####
This DSC resource can be used to deploy NAT configuration with Hyper-V VM switches. This works only with Server 2106 TP4 onwards.

This is a very simple resource. It creates a VM switch of NAT type and configures a NAT on the management OS.

![](http://i.imgur.com/yaFN6dT.png)
The *Name* property identifies the name of the VM switch and the *NATSubnetAddress* properties identifies the address range that should be used for nat'ing.

Here is how you use this resource.

    Configuration NatDemo {
    	Import-DscResource -ModuleName cHyper-V -Name cNatSwitch
    	cNatSwitch NatDemo {
    		Name = 'SQLNatConfig'
    		NATSubnetAddress = '192.168.0.0/24'
    		Ensure = 'Present'
    	}
    }
 
####Using cVMNetworkAdapter resource####
This DSC resource can be used to attach network adapters to VM switches and add them to either management OS or virtual machines on the host.

![](http://i.imgur.com/eQjUD9h.png)

The Id property is the unique key within this DSC resource. This property isn't related to any VM network adapter configuration but instead used as a way to uniquely identify each VM network adapter resource in a configuration. In the previous version of this DSC resource, *Name* property was the key property. There it prevented creating network adapters with the same name and attach them to different VMs. This is a breaking change. The Name property and *SwitchName* property identify the name to be assigned to the VM network adapter and the name of the switch to attach to. The *ManagementOS* property identifies if the adapter should be added to the management OS instead of a VM. The *ManagementOS* and *VMName* properties are mutually exclusive. *VMName* property idenitifies the virtual machine to which the VM network adapter will be attached to. If you want to assign a static MAC address to the VM network adapter, you can use the *StaticMacAddress* property. To reset it back to a dynamic MAC address, simply remove the *StaticMacAddress* and configure the *DynamicMacAddress* to be $true.

Here is an example of how you use this DSC resource.

    cVMNetworkAdapter TestNet {
    	Id = ([guid]::NewGuid()).guid
    	Name = 'DemoAdapter'
    	SwitchName = 'DemoSwitch'
    	ManagementOS = $true
    	Ensure = 'Present'
    	DependsOn = "[cVMSwitch]DemoSwitch"
    }

####Using cVMNetworkAdapterVlan resource####
This DSC resource can be used to assign VLAN information to a NIC that is created attached to either the management OS or a virtual machine. There are several possibilities here.

![](http://i.imgur.com/coUmOKg.png)

This resource has two mandatory property. The Id property is just a unique identifier to differentiate between multiple VMs containing the same network adapter name. You must also specify the Name of the adapter and whether that belongs to *ManagementOS* or not. If the VM adapter belongs to a VM, you should specify a VM name using the *VMName* property. The *AdapterMode* property specifies the operation mode of the adapter and is by default set to *Untagged* which means there is not VLAN configuration. The possible and valid values for this property are *Untagged*, *Access*, *Trunk*, *Community*, *Isolated*, and *Promiscuous*. Each of these modes have a corresponding VLAN property that is mandatory. For example, if you set the *AdapterMode* property to Access, then it is mandatory to provide *VlanId* property. Similarly, if you set the *AdapterMode* to Trunk, the *NativeVlanId* property must be specified.

Here is a sample configuration script that shows cNetworkAdapterVlan resource in action.

    cVMNetworkAdapterVlan HostSwitchVlan {
       Id = ([guid]::NewGuid()).guid
       Name = 'HostSwitch'
       ManagementOS = $true
       AdapterMode = 'Access'
       VlanId = 10
       DependsOn = '[cVMSwitch]HostSwitch'
    }

####Using cVMNetworkAdapterSettings resource####
Once the VM network adapters are created, we can assign the bandwidth reservation or priority settings as needed. Since we set the MinimumBandwidthMode to Weight during VM switch creation, we need to specify the percentage of bandwidth reservation for each adapter.  We use cVMNetworkAdapterSettings DSC resource for this purpose. This DSC resource can used for many other settings such as DhcpGuard, RouterGuard and so on.

![](http://i.imgur.com/eaG6bl7.png)

There are three mandatory properties in this DSC resource. You must specify the *Id*, *Name* and *SwitchName* properties. The *ManagementOS* and *VMName* properties are mutually exclusive. The Id property works in a similar way as the cVMNetworkAdapter or cVMNetworkAdapterVlan resources.

The *MaximumBandwidth* property is used to specify the maximum bandwidth, in bits per second, for the virtual network adapter. The *MinimumBandwidthAbsolute* specifies the minimum bandwidth, in bits per second, for the virtual network adapter. By default, these properties are set to zero which means those parameters within the network adapter are disabled. The *MinimumBandwidthWeight* specifies the minimum bandwidth, in terms of relative weight, for the virtual network adapter. The weight describes how much bandwidth to provide to the virtual network adapter relative to other virtual network adapters connected to the same virtual switch.

If you want allow teaming of network adapters in the guest OS, you can set the *AllowTeaming* property to On. By default, this is set to Off and therefore disallows network teaming inside guest OS. Similar to this, there are other settings of a VM network adapter that you can configure. These properties include *DhcpGuard*, *MacAddressSpoofing*, *PortMirroring*, *RouterGuard*, *IeeePriorityTag*, and *VmqWeight*. These properties are self explanatory and are left to defaults for a VM network adapter.

Here is a sample configuration using this resource.

    cVMNetworkAdapterSettings HostClusterSettings {
       Id = ([guid]::NewGuid()).guid
       Name = 'HostCluster'
       SwitchName = 'HostSwitch'
       ManagementOS = $true
       MinimumBandwidthWeight = 10
       DependsOn = '[cVMSwitch]HostSwitch','[cVMNetworkAdapter]HostCluster'
    }