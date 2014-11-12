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

    $LogFileConsumer = Get-CimInstance -Namespace 'root\subscription' -Query "SELECT * FROM LogFileEventConsumer WHERE Name='$Name'"
    if ($LogFileConsumer) {
        $Configuration.Add('Ensure','Present')
        $Configuration.Add('MaximumFileSize',$LogFileConsumer.MaximumFileSize)
        $Configuration.Add('IsUnicode',$LogFileConsumer.IsUnicode)
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
        Write-Verbose "Creating a new LogFile Consumer instance with name ${Name}"
        
        if (-not [System.IO.Path]::IsPathRooted($Filename)) {
            $Filename = [System.IO.Path]::GetFullPath($Filename)
            Write-Verbose "Found a relative path for the filename. The converted full path is ${FileName}"
        }
        
        New-CimInstance -Namespace 'root\subscription' -ClassName 'LogFileEventConsumer' -Property @{
            Name = $Name
            FileName = $Filename
            Text = $Text
            MaximumFileSize = $MaximumFileSize
            IsUnicode = $IsUnicode
        }
    } else {
        Write-Verbose "Removing a LogFile Consumer instance with name ${Name}"
        Remove-CimInstance -Namespace 'root\subscription' -Query "SELECT * FROM LogFileEventConsumer WHERE Name='$Name'"
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

    $LogFileConsumer = Get-CimInstance -Namespace 'root\subscription' -Query "SELECT * FROM LogFileEventConsumer WHERE Name='$Name'"
    
    if ($Ensure -eq 'Present') {
        if ($LogFileConsumer) {
            Write-Verbose "Log File consumer with the name ${Name} already exists. No action needed"
            return $true
        } else {
            Write-Verbose "Log File consumer with the name ${Name} does not exist. It will be created"
            return $false
        }
    } else {
        if ($LogFileConsumer) {
            Write-Verbose "Log File consumer with the name ${Name} already exists. It will be removed"
            return $false
        } else {
            Write-Verbose "Log File consumer with the name ${Name} does not exist. No action needed"
            return $true
        }
    }
}