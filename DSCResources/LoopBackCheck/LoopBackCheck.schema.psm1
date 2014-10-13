Configuration LoopBackCheck {
    Param (
        [Parameter()]
        [ValidateSet("Present","Absent")]
        [String]$Ensure = "Present"
    )

    Registry DefaultDomainName
    {
        Ensure = $Ensure
        Key = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa'
        ValueName = 'DisableLoopbackCheck'
        ValueData = 1
        ValueType = 'DWord'
    }
}