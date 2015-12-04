# Fallback message strings in en-US
DATA localizedData
{
# same as culture = "en-US"
ConvertFrom-StringData @'    
    GettingConsumerInstance=Getting Consumer Instance named {0}.
    ConsumerInstanceFound=Consumer Instance named {0} is found.
    ConsumerInstanceNotFound=Getting Consumer Instance named {0} not found.
    CreatingConsumerInstance=Creating Consumer Instance named {0}.
    NotAbsolutePath=FileName value {0} provided is not absolte path. It will be converted to absolutepath.
    CreatedConsumerInstance=Created Consumer Instance named {0}.
    RemovingConsumerInstance=Removing Consumer Instance named {0}.
    RemovedConsumerInstance=Removed Consumer Instance named {0}.
    ConsumerExistsNoAction=Consumer Instance named {0} already exists. No action needed.
    ConsumerDoesNotExistShouldCreate=Consumer Instance named {0} does not exist. It will be created.
    ConsumerExistsShouldRemove=Consumer Instance named {0} exists. This will be removed.
    ConsumerDoesNotExistNoAction=Consumer Instance named {0} not found. No action needed.
'@
}

if (Test-Path "$PSScriptRoot\$PSUICulture")
{
    Import-LocalizedData LocalizedData -filename WMILogFileConsumer.psd1 -baseDirectory "$PSScriptRoot\$PSUICulture"
}

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param (
        [Parameter(Mandatory)]
        [string] $Name,

        [Parameter(Mandatory)]
        [String] $Filename,

        [Parameter(Mandatory)]
        [String] $Text
    )

    $Configuration = @{
        Name = $Name
        Filename = $Filename
        Text = $Text
    }
    
    Write-Verbose ($localizedData.GettingConsumerInstance -f $Name)
    $LogFileConsumer = Get-CimInstance -Namespace 'root\subscription' -Query "SELECT * FROM LogFileEventConsumer WHERE Name='$Name'"

    if ($LogFileConsumer) {
        Write-Verbose ($localizedData.ConsumerInstanceFound -f $Name)
        $Configuration.Add('Ensure','Present')
        $Configuration.Add('MaximumFileSize',$LogFileConsumer.MaximumFileSize)
        $Configuration.Add('IsUnicode',$LogFileConsumer.IsUnicode)
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
        [String] $Filename,

        [Parameter(Mandatory)]
        [String] $Text,

        [Parameter()]
        [uint64] $MaximumFileSize = 65535,

        [Parameter()]
        [Bool] $IsUnicode = $true,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )

    if ($Ensure -eq 'Present') {
        Write-Verbose ($localizedData.CreatingConsumerInstance -f $Name)
        
        if (-not [System.IO.Path]::IsPathRooted($Filename)) {
            $Filename = [System.IO.Path]::GetFullPath($Filename)
            Write-Verbose ($localizedData.NotAbsolutePath -f $Filename)
        }
        
        New-CimInstance -Namespace 'root\subscription' -ClassName 'LogFileEventConsumer' -Property @{
            Name = $Name
            FileName = $Filename
            Text = $Text
            MaximumFileSize = $MaximumFileSize
            IsUnicode = $IsUnicode
        }
        Write-Verbose ($localizedData.CreatedConsumerInstance -f $Name)
    } else {
        Write-Verbose ($localizedData.RemovingConsumerInstance -f $Name)
        Remove-CimInstance -Namespace 'root\subscription' -Query "SELECT * FROM LogFileEventConsumer WHERE Name='$Name'"
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
        [String] $Filename,

        [Parameter(Mandatory)]
        [String] $Text,

        [Parameter()]
        [uint64] $MaximumFileSize = 65535,

        [Parameter()]
        [Bool] $IsUnicode = $true,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )

    Write-Verbose ($localizedData.GettingConsumerInstance -f $Name)
    $LogFileConsumer = Get-CimInstance -Namespace 'root\subscription' -Query "SELECT * FROM LogFileEventConsumer WHERE Name='$Name'"
    
    if ($Ensure -eq 'Present') {
        if ($LogFileConsumer) {
            Write-Verbose ($localizedData.ConsumerExistsNoAction -f $Name)
            return $true
        } else {
            Write-Verbose ($localizedData.ConsumerDoesNotExistShouldCreate -f $Name)
            return $false
        }
    } else {
        if ($LogFileConsumer) {
            Write-Verbose ($localizedData.ConsumerExistsShouldRemove -f $Name)
            return $false
        } else {
            Write-Verbose ($localizedData.ConsumerDoesNotExistNoAction -f $Name)
            return $true
        }
    }
}