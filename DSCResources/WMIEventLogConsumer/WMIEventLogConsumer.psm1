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

    $NTEventLogEventConsumer = Get-CimInstance -Namespace 'root\subscription' -Query "SELECT * FROM NTEventLogEventConsumer WHERE Name='$Name'"
    if ($NTEventLogEventConsumer) {
        $Configuration.Add('Ensure','Present')
        $Configuration.Add('Category',$NTEventLogEventConsumer.Cateogry)
        $Configuration.Add('EventType', $NTEventLogEventConsumer.EventType)
        $Configuration.Add('NumberOfInsertionStrings', $NTEventLogEventConsumer.NumberOfInsertionStrings)
        $Configuration.Add('SourceName', $NTEventLogEventConsumer.SourceName)
        $Configuration.Add('UNCServerName',$NTEventLogEventConsumer.UNCServerName)
        $Configuration.Add('InsertionStringTemplates',$NTEventLogEventConsumer.InsertionStringTemplates)
    } else {
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
        Write-Verbose "Creating an NT Event Log Consumer instance with name ${Name}"
        
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
    } else {
        Write-Verbose "Removing an NT Event Log Consumer instance with name ${Name}"
        Remove-CimInstance -Namespace 'root\subscription' -Query "SELECT * FROM NTEventLogEventConsumer WHERE Name='$Name'"
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

    $NTEventLogEventConsumer = Get-CimInstance -Namespace 'root\subscription' -Query "SELECT * FROM NTEventLogEventConsumer WHERE Name='$Name'"
    
    if ($Ensure -eq 'Present') {
        if ($NTEventLogEventConsumer) {
            Write-Verbose "NT Event Log consumer with the name ${Name} already exists. No action needed"
            return $true
        } else {
            Write-Verbose "NT Event Log consumer with the name ${Name} does not exist. It will be created"
            return $false
        }
    } else {
        if ($NTEventLogEventConsumer) {
            Write-Verbose "NT Event Log consumer with the name ${Name} already exists. It will be removed"
            return $false
        } else {
            Write-Verbose "NT Event Log consumer with the name ${Name} does not exist. No action needed"
            return $true
        }
    }
}