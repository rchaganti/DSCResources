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

    $SMTPEventConsumer = Get-CimInstance -Namespace 'root\subscription' -Query "SELECT * FROM SMTPEventConsumer WHERE Name='$Name'"
    if ($SMTPEventConsumer) {
        $Configuration.Add('Ensure','Present')
        $Configuration.Add('Message',$SMTPEventConsumer.Message)
        $Configuration.Add('Subject',$SMTPEventConsumer.Subject)
        $Configuration.Add('CcLine',$SMTPEventConsumer.CcLine)
        $Configuration.Add('BccLine',$SMTPEventConsumer.CcLine)
        $Configuration.Add('ReplyToLine',$SMTPEventConsumer.CcLine)
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
        Write-Verbose "Creating a new SMTP Consumer instance with name ${Name}"
        
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

        New-CimInstance -Namespace 'root\subscription' -ClassName 'SMTPEventConsumer' -Property $Properties
    } else {
        Write-Verbose "Removing an SMTP Consumer instance with name ${Name}"
        Remove-CimInstance -Namespace 'root\subscription' -Query "SELECT * FROM SMTPEventConsumer WHERE Name='$Name'"
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

    $SMTPEventConsumer = Get-CimInstance -Namespace 'root\subscription' -Query "SELECT * FROM SMTPEventConsumer WHERE Name='$Name'"
    
    if ($Ensure -eq 'Present') {
        if ($SMTPEventConsumer) {
            Write-Verbose "SMTP consumer with the name ${Name} already exists. No action needed"
            return $true
        } else {
            Write-Verbose "SMTP with the name ${Name} does not exist. It will be created"
            return $false
        }
    } else {
        if ($SMTPEventConsumer) {
            Write-Verbose "SMTP with the name ${Name} already exists. It will be removed"
            return $false
        } else {
            Write-Verbose "SMTP with the name ${Name} does not exist. No action needed"
            return $true
        }
    }
}