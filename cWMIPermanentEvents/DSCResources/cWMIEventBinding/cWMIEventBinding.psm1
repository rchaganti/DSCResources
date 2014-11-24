# Fallback message strings in en-US
DATA localizedData
{
# same as culture = "en-US"
ConvertFrom-StringData @'    
    GettingFilterToConsumerBinding="Retreiving any avilable bindings for {0} and {1} of type {2}".
    BindingFound="Binding found for filter {0}, consumer {1} of type {2}".
    BindingNotFound="Binding found for filter {0}, consumer {1} of type {2}".
    GettingFilterAndConsumer="Retrieving Filter and Consumer instances for {0} and {1}".
    FilterAndConsumerCannotBeCreated="Filter and Consumer instances cannot be created for filter {0} and consumer {1}".
    CreatingFilterToConsumerBinding="Creating event binding for filter {0} and consumer {1} of type {2}".
    CreatedEventBinding="Created event binding for filter {0} and consumer {1} of type {2}".
    RemovingEventBinding="Removing event binding for filter {0} and consumer {1} of type {2}".
    RemovedEventBinding="Removed event binding for filter {0} and consumer {1} of type {2}".
    EventBindingExistsNoAction="Event binding for filter {0} and consumer {1} of type {2} exists. No action needed.".
    EventBindingDoesNotExistShouldCreate="Event binding for filter {0} and consumer {1} of type {2} does not exist. It will be created".
    EventBindingExistsShouldDelete="Event binding for filter {0} and consumer {1} of type {2} exits. It should be deleted".
    EventBindingDoesNotExistNoAction="Event binding for filter {0} and consumer {1} of type {2} does not exist. No action needed".
'@
}

if (Test-Path $PSScriptRoot\en-us)
{
    Import-LocalizedData LocalizedData -filename WMIEventBinding.psd1
}

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

    Write-Verbose ($localizedData.GettingFilterToConsumerBinding -f $Filter, $Consumer, $ConsumerType)
    $Binding = Get-CimInstance -Namespace 'root\subscription' -ClassName __FilterToConsumerBinding | Where-Object { ($_.Filter.Name -eq $Filter) -and ($_.Consumer.Name -eq $Consumer) }

    if ($Binding) {
        Write-Verbose ($localizedData.BindingFound -f $Filter, $Consumer, $ConsumerType)
        $Configuration.Add('ConsumerType',$Binding.Consumer.CimClass.CimClassName)
        $Configuration.Add('Ensure','Present')
    } else {
        Write-Verbose ($localizedData.BindingNotFound -f $Filter, $Consumer, $ConsumerType)
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
        Write-Verbose ($localizedData.GettingFilterAndConsumer -f $Filter, $Consumer)

        try {
            $FilterObject = Get-CimInstance -ClassName '__EventFilter' -Namespace 'root\subscription' -Filter "Name='${filter}'"
            $ConsumerObject = Get-CimInstance -ClassName $ConsumerHash[$ConsumerType] -Namespace 'root\subscription' -Filter "Name='${Consumer}'"
        }
        catch {
            throw ($localizedData.FilterAndConsumerCannotBeCreated -f $Filter, $Consumer, $ConsumerType)
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

        Write-Verbose ($localizedData.CreatingFilterToConsumerBinding -f $Filter, $Consumer, $ConsumerType)
        New-CimInstance -ClassName '__FilterToConsumerBinding' -Namespace 'root\subscription' -Property $BinderHash
        Write-Verbose ($localizedData.CreatedEventBinding -f $Filter, $Consumer, $ConsumerType)
    } else {
        Write-Verbose ($localizedData.RemovingEventBinding -f $Filter, $Consumer, $ConsumerType)
        $binding = Get-CimInstance -Namespace 'root\subscription' -ClassName __FilterToConsumerBinding | Where-Object { ($_.Filter.Name -eq $Filter) -and ($_.Consumer.Name -eq $Consumer) }
        Remove-CimInstance -InputObject $binding
        Write-Verbose ($localizedData.RemovedEventBinding -f $Filter, $Consumer, $ConsumerType)
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
    
    Write-Verbose ($localizedData.GettingFilterToConsumerBinding -f $Filter, $Consumer, $ConsumerType)
    $binding = Get-CimInstance -Namespace 'root\subscription' -ClassName __FilterToConsumerBinding | Where-Object { ($_.Filter.Name -eq $Filter) -and ($_.Consumer.Name -eq $Consumer) }

    if ($Ensure -eq 'Present') {
        if ($binding) {
            Write-Verbose ($localizedData.EventBindingExistsNoAction -f $Filter, $Consumer, $ConsumerType)
            return $true
        } else {
            Write-Verbose ($localizedData.EventBindingDoesNotExistShouldCreate -f $Filter, $Consumer, $ConsumerType)
            return $false
        }
    } else {
        if ($binding) {
            Write-Verbose ($localizedData.EventBindingExistsShouldDelete -f $Filter, $Consumer, $ConsumerType)
            return $false
        } else {
            Write-Verbose ($localizedData.EventBindingDoesNotExistNoAction -f $Filter, $Consumer, $ConsumerType)
            return $true
        }
    }
}