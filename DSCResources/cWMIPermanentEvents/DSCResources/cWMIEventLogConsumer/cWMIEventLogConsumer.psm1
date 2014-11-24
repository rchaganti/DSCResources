# Fallback message strings in en-US
DATA localizedData
{
# same as culture = "en-US"
ConvertFrom-StringData @'    
    GettingConsumerInstance=Getting Consumer Instance named {0}.
    ConsumerInstanceFound=Consumer Instance named {0} is found.
    ConsumerInstanceNotFound=Getting Consumer Instance named {0} not found.
    CreatingConsumerInstance=Creating Consumer Instance named {0}.
    CreatedConsumerInstance=Created Consumer Instance named {0}.
    RemovingConsumerInstance=Removing Consumer Instance named {0}.
    RemovedConsumerInstance=Removed Consumer Instance named {0}.
    ConsumerExistsNoAction=Consumer Instance named {0} already exists. No action needed.
    ConsumerDoesNotExistShouldCreate=Consumer Instance named {0} does not exist. It will be created.
    ConsumerExistsShouldRemove=Consumer Instance named {0} exists. This will be removed.
    ConsumerDoesNotExistNoAction=Consumer Instance named {0} not found. No action needed.
'@
}

if (Test-Path $PSScriptRoot\en-us)
{
    Import-LocalizedData LocalizedData -filename WMIEventLogConsumer.psd1
}

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param (
        [Parameter(Mandatory)]
        [string] $Name,

        [Parameter(Mandatory)]
        [uint32] $EventID
    )

    $Configuration = @{
        Name = $Name
        EventID = $EventID
    }
    
    Write-Verbose ($localizedData.GettingConsumerInstance -f $Name)
    $NTEventLogEventConsumer = Get-CimInstance -Namespace 'root\subscription' -Query "SELECT * FROM NTEventLogEventConsumer WHERE Name='$Name'"
    
    if ($NTEventLogEventConsumer) {
        Write-Verbose ($localizedData.ConsumerInstanceFound -f $Name)
        $Configuration.Add('Ensure','Present')
        $Configuration.Add('Category',$NTEventLogEventConsumer.Cateogry)
        $Configuration.Add('EventType', $NTEventLogEventConsumer.EventType)
        $Configuration.Add('NumberOfInsertionStrings', $NTEventLogEventConsumer.NumberOfInsertionStrings)
        $Configuration.Add('SourceName', $NTEventLogEventConsumer.SourceName)
        $Configuration.Add('UNCServerName',$NTEventLogEventConsumer.UNCServerName)
        $Configuration.Add('InsertionStringTemplates',$NTEventLogEventConsumer.InsertionStringTemplates)
    } else {
        Write-Verbose ($localizedData.ConsumerInstanceNotFound -f $Name)
        $Configuration.Add('Ensure','Absent')
    }

    return $Configuration
}

function Set-TargetResource
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $Name,

        [Parameter(Mandatory)]
        [uint32] $EventID,

        [Parameter()]
        [uint16] $Category=10,

        [Parameter()]
        [ValidateSet('Sucess','Error','Warning','Information','AuditSuccess','AuditFailure')]
        [string] $EventType = 'Error',

        [Parameter()]
        [uint32] $NumberOfInsertionStrings=1,

        [Parameter()]
        [String] $SourceName='PermanentConsumer',

        [Parameter()]
        [String] $UNCServerName,

        [Parameter()]
        [string[]] $InsertionStringTemplates,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )

    $EventTypeHash = @{
        Success = 0
        Error = 1
        Warning = 2
        Information = 4
        AuditSuccess = 8
        AuditFailure = 16
    }

    if ($Ensure -eq 'Present') {
        Write-Verbose ($localizedData.CreatingConsumerInstance -f $Name)
        $Properties = @{
            Name = $Name
            Category = $Category
            EventID = $EventID
            EventType = [uint32]$EventTypeHash[$EventType]
            NumberOfInsertionStrings = $NumberOfInsertionStrings
            SourceName = $SourceName
        }

        if ($UNCServerName) {
            $Properties.Add('UNCServerName',$UNCServerName)
        }

        if ($InsertionStringTemplates) {
            if ($InsertionStringTemplates.Count -gt 1) {
                $Properties.Add('InsertionStringTemplates',$InsertionStringTemplates -join ',')
            } else {
                $Properties.Add('InsertionStringTemplates',$InsertionStringTemplates)
            }
        }

        New-CimInstance -Namespace 'root\subscription' -ClassName 'NTEventLogEventConsumer' -Property $Properties
        Write-Verbose ($localizedData.CreatedConsumerInstance -f $Name)
    } else {
        Write-Verbose ($localizedData.RemovingConsumerInstance -f $Name)
        Remove-CimInstance -Namespace 'root\subscription' -Query "SELECT * FROM NTEventLogEventConsumer WHERE Name='$Name'"
        Write-Verbose ($localizedData.RemovedConsumerInstance -f $Name)
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([Bool])]
    param (
        [Parameter(Mandatory)]
        [string] $Name,

        [Parameter()]
        [uint16] $Category=10,

        [Parameter(Mandatory)]
        [uint32] $EventID,

        [Parameter()]
        [ValidateSet('Sucess','Error','Warning','Information','AuditSuccess','AuditFailure')]
        [string] $EventType = 'Error',

        [Parameter()]
        [uint32] $NumberOfInsertionStrings=1,

        [Parameter()]
        [String] $SourceName='PermanentConsumer',

        [Parameter()]
        [String] $UNCServerName,

        [Parameter()]
        [string[]] $InsertionStringTemplates,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )

    Write-Verbose ($localizedData.GettingConsumerInstance -f $Name)
    $NTEventLogEventConsumer = Get-CimInstance -Namespace 'root\subscription' -Query "SELECT * FROM NTEventLogEventConsumer WHERE Name='$Name'"
    
    if ($Ensure -eq 'Present') {
        if ($NTEventLogEventConsumer) {
            Write-Verbose ($localizedData.ConsumerExistsNoAction -f $Name)
            return $true
        } else {
            Write-Verbose ($localizedData.ConsumerDoesNotExistShouldCreate -f $Name)
            return $false
        }
    } else {
        if ($NTEventLogEventConsumer) {
            Write-Verbose ($localizedData.ConsumerExistsShouldRemove -f $Name)
            return $false
        } else {
            Write-Verbose ($localizedData.ConsumerDoesNotExistNoAction -f $Name)
            return $true
        }
    }
}