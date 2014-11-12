$ConsumerHash = @{
    LogFile = 'LogFileEventConsumer'
    EventLog = 'NTEventLogEventConsumer'
    CommandLine = 'CommandLineEventConsumer'
    Script = 'ActiveScriptEventConsumer'
    SMTP = 'SMTPEventConsumer'
}

$DeliveryQoSHash = @{
    Synchronous = 0
    Express = 1
}

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param (
        [Parameter(Mandatory)]
        [String] $Filter,

        [Parameter(Mandatory)]
        [String] $Consumer,

        [Parameter(Mandatory)]
        [ValidateSet('LogFile','EventLog','CommandLine','Script','SMTP')]
        [String] $ConsumerType
    )

    $Configuration = @{
        Filter = $Filter
        Consumer = $Consumer
    }    

    Write-Verbose "Retreiving any avilable bindings for ${filter} and ${consumer} of type ${ConsumerType}"
    $Binding = Get-CimInstance -Namespace 'root\subscription' -ClassName __FilterToConsumerBinding | Where-Object { ($_.Filter.Name -eq $Filter) -and ($_.Consumer.Name -eq $Consumer) }

    if ($Binding) {
        Write-Verbose "Filter to Consumer binding for ${filter} and ${Consumer} of type ${ConsumerType} exists"
        $Configuration.Add('ConsumerType',$Binding.Consumer.CimClass.CimClassName)
        $Configuration.Add('Ensure','Present')
    } else {
        Write-Verbose "Filter to Consumer binding for ${filter} and ${Consumer} of type ${ConsumerType} does not exist"
        $Configuration.Add('Ensure','Absent')
    }

    $Configuration
}

function Set-TargetResource
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String] $Filter,

        [Parameter(Mandatory)]
        [String] $Consumer,

        [Parameter(Mandatory)]
        [ValidateSet('LogFile','EventLog','CommandLine','Script','SMTP')]
        [String] $ConsumerType,

        [Parameter()]
        [Boolean] $MaintainSecurityContext = $false,

        [Parameter()]
        [Boolean] $SlowDownProviders = $false,

        [Parameter()]
        [ValidateSet('Synchronous', 'Express')]
        [string] $DeliveryQoS,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String] $Ensure = 'Present'
    )

    if ($Ensure -eq 'Present') {
        Write-Verbose "Retreiving filter and consumer objects ..."

        try {
            $FilterObject = Get-CimInstance -ClassName '__EventFilter' -Namespace 'root\subscription' -Filter "Name='${filter}'"
            $ConsumerObject = Get-CimInstance -ClassName $ConsumerHash[$ConsumerType] -Namespace 'root\subscription' -Filter "Name='${Consumer}'"
        }
        catch {
            throw "Filter and Consumer objects could not be created"
        }
        
        $BinderHash = @{
            Filter = [ref]$FilterObject
            Consumer = [ref]$ConsumerObject
            MaintainSecurityContext = $MaintainSecurityContext
            SlowDownProviders = $SlowDownProviders
        }

        if ($DeliveryQoS) {
            $BinderHash.Add('DeliveryQoS', [uint32]($DeliveryQoSHash[$DeliveryQoS]))
        }

        Write-Verbose "Creating a ${filter} to ${consumer} binding ..."
        New-CimInstance -ClassName '__FilterToConsumerBinding' -Namespace 'root\subscription' -Property $BinderHash
    } else {
        $binding = Get-CimInstance -Namespace 'root\subscription' -ClassName __FilterToConsumerBinding | Where-Object { ($_.Filter.Name -eq $Filter) -and ($_.Consumer.Name -eq $Consumer) }
        Write-Verbose "Remove filter ${filter} to consumer ${consumer} binding ..."
        Remove-CimInstance -InputObject $binding
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([boolean])]
    param (
        [Parameter(Mandatory)]
        [String] $Filter,

        [Parameter(Mandatory)]
        [String] $Consumer,

        [Parameter(Mandatory)]
        [ValidateSet('LogFile','EventLog','CommandLine','Script','SMTP')]
        [String] $ConsumerType,

        [Parameter()]
        [Boolean] $MaintainSecurityContext = $false,

        [Parameter()]
        [Boolean] $SlowDownProviders = $false,

        [Parameter()]
        [ValidateSet('Synchronous', 'Express')]
        [string] $DeliveryQoS,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String] $Ensure = 'Present'
    )
    
    Write-Verbose "Retreiving any avilable bindings for ${filter} and ${consumer} of type ${ConsumerType}"
    $binding = Get-CimInstance -Namespace 'root\subscription' -ClassName __FilterToConsumerBinding | Where-Object { ($_.Filter.Name -eq $Filter) -and ($_.Consumer.Name -eq $Consumer) }

    if ($Ensure -eq 'Present') {
        if ($binding) {
            Write-Verbose "${Filter} to ${Consumer} binder exists already. No action needed"
            return $true
        } else {
            Write-Verbose "${Filter} to ${Consumer} binder does not exist. It will be created"
            return $false
        }
    } else {
        if ($binding) {
            Write-Verbose "${Filter} to ${Consumer} binder exists already. It will be removed"
            return $false
        } else {
            Write-Verbose "${Filter} to ${Consumer} binder does not exist. No action needed"
            return $true
        }
    }
}