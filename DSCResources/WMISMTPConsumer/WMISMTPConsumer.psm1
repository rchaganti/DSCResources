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
    Import-LocalizedData LocalizedData -filename WMISMTPConsumer.psd1
}

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param (
        [Parameter(Mandatory)]
        [string] $Name,

        [Parameter(Mandatory)]
        [String] $ToLine,

        [Parameter(Mandatory)]
        [String] $FromLine,

        [Parameter(Mandatory)]
        [String] $SMTPServer,

        [Parameter()]
        [String] $Message,

        [Parameter()]
        [String] $Subject,

        [Parameter()]
        [String] $CcLine,

        [Parameter()]
        [String] $BccLine,

        [Parameter()]
        [String] $ReplyToLine
    )

    $Configuration = @{
        Name = $Name
        ToLine = $ToLine
        FromLine = $FromLine
        SMTPServer = $SMTPServer
    }

    Write-Verbose ($localizedData.GettingConsumerInstance -f $Name)
    $SMTPEventConsumer = Get-CimInstance -Namespace 'root\subscription' -Query "SELECT * FROM SMTPEventConsumer WHERE Name='$Name'"
    if ($SMTPEventConsumer) {
        Write-Verbose ($localizedData.ConsumerInstanceFound -f $Name)
        $Configuration.Add('Ensure','Present')
        $Configuration.Add('Message',$SMTPEventConsumer.Message)
        $Configuration.Add('Subject',$SMTPEventConsumer.Subject)
        $Configuration.Add('CcLine',$SMTPEventConsumer.CcLine)
        $Configuration.Add('BccLine',$SMTPEventConsumer.CcLine)
        $Configuration.Add('ReplyToLine',$SMTPEventConsumer.CcLine)
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
        [String] $ToLine,

        [Parameter(Mandatory)]
        [String] $FromLine,

        [Parameter(Mandatory)]
        [String] $SMTPServer,

        [Parameter()]
        [String] $Message,

        [Parameter()]
        [String] $Subject,

        [Parameter()]
        [String] $CcLine,

        [Parameter()]
        [String] $BccLine,

        [Parameter()]
        [String] $ReplyToLine,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )

    if ($Ensure -eq 'Present') {
        Write-Verbose ($localizedData.CreatingConsumerInstance -f $Name)
        $Properties = @{
            Name = $Name
            ToLine = $ToLine
            FromLine = $FromLine
            SMTPServer = $SMTPServer
        }

        if ($Message) {
            $Properties.Add('Message',$Message)
        }

        if ($Subject) {
            $Properties.Add('Subject',$Subject)
        }

        if ($CcLine) {
            $Properties.Add('CcLine',$CcLine)
        }

        if ($BccLine) {
            $Properties.Add('BccLine',$BccLine)
        }

        if ($ReplyToLine) {
            $Properties.Add('ReplyToLine',$ReplyToLine)
        }
        Write-Verbose ($localizedData.CreatedConsumerInstance -f $Name)
        New-CimInstance -Namespace 'root\subscription' -ClassName 'SMTPEventConsumer' -Property $Properties
    } else {
        Write-Verbose ($localizedData.RemovingConsumerInstance -f $Name)
        Remove-CimInstance -Namespace 'root\subscription' -Query "SELECT * FROM SMTPEventConsumer WHERE Name='$Name'"
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

        [Parameter(Mandatory)]
        [String] $ToLine,

        [Parameter(Mandatory)]
        [String] $FromLine,

        [Parameter(Mandatory)]
        [String] $SMTPServer,

        [Parameter()]
        [String] $Message,

        [Parameter()]
        [String] $Subject,

        [Parameter()]
        [String] $CcLine,

        [Parameter()]
        [String] $BccLine,

        [Parameter()]
        [String] $ReplyToLine,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )

    Write-Verbose ($localizedData.GettingConsumerInstance -f $Name)
    $SMTPEventConsumer = Get-CimInstance -Namespace 'root\subscription' -Query "SELECT * FROM SMTPEventConsumer WHERE Name='$Name'"
    
    if ($Ensure -eq 'Present') {
        if ($SMTPEventConsumer) {
            Write-Verbose ($localizedData.ConsumerExistsNoAction -f $Name)
            return $true
        } else {
            Write-Verbose ($localizedData.ConsumerDoesNotExistShouldCreate -f $Name)
            return $false
        }
    } else {
        if ($SMTPEventConsumer) {
            bose ($localizedData.ConsumerExistsShouldRemove -f $Name)
            return $false
        } else {
            Write-Verbose ($localizedData.ConsumerDoesNotExistNoAction -f $Name)
            return $true
        }
    }
}