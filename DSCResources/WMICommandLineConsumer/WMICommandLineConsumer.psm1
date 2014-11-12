function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param (
        [Parameter(Mandatory)]
        [string] $Name,

        [Parameter(Mandatory)]
        [String] $CommandLineTemplate,

        [Parameter()]
        [String] $ExecutablePath,

        [Parameter()]
        [String] $WorkingDirectory
    )

    $Configuration = @{
        Name = $Name
        CommandLineTemplate = $CommandLineTemplate
    }

    $ScriptConsumer = Get-CimInstance -Namespace 'root\subscription' -Query "SELECT * FROM CommandLineEventConsumer  WHERE Name='$Name'"
    if ($ScriptConsumer) {
        $Configuration.Add('Ensure','Present')
        $Configuration.Add('ExecutablePath',$CommandLineEventConsumer.ExecutablePath)
        $Configuration.Add('WorkingDirectory',$CommandLineEventConsumer.WorkingDirectory)
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
        [String] $CommandLineTemplate,

        [Parameter()]
        [String] $ExecutablePath,

        [Parameter()]
        [String] $WorkingDirectory,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )

    if ($Ensure -eq 'Present') {
        Write-Verbose "Creating a new commandline Consumer instance with name ${Name}"
        
        
        $Properties = @{
            Name = $Name
            CommandLineTemplate = $CommandLineTemplate
        }

        if ($ExecutablePath) {
            if (-not [System.IO.Path]::IsPathRooted($ExecutablePath)) {
                Throw "${ExecutablePath} is relative and cannot be processed"
            } else {
                $Properties.Add('ExecutablePath', $ExecutablePath)
            }
        }

        if ($WorkingDirectory) {
            $Properties.Add('WorkingDirectory',$WorkingDirectory)
        }

        New-CimInstance -Namespace 'root\subscription' -ClassName 'CommandLineEventConsumer' -Property $Properties
    } else {
        Write-Verbose "Removing an Active Script Consumer instance with name ${Name}"
        Remove-CimInstance -Namespace 'root\subscription' -Query "SELECT * FROM CommandLineEventConsumer WHERE Name='$Name'"
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
        [String] $CommandLineTemplate,

        [Parameter()]
        [String] $ExecutablePath,

        [Parameter()]
        [String] $WorkingDirectory,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )

    $CommandLineEventConsumer = Get-CimInstance -Namespace 'root\subscription' -Query "SELECT * FROM CommandLineEventConsumer WHERE Name='$Name'"
    
    if ($Ensure -eq 'Present') {
        if ($CommandLineEventConsumer) {
            Write-Verbose "Active Script consumer with the name ${Name} already exists. No action needed"
            return $true
        } else {
            Write-Verbose "Active Script consumer with the name ${Name} does not exist. It will be created"
            return $false
        }
    } else {
        if ($CommandLineEventConsumer) {
            Write-Verbose "Active Script consumer with the name ${Name} already exists. It will be removed"
            return $false
        } else {
            Write-Verbose "Active Script consumer with the name ${Name} does not exist. No action needed"
            return $true
        }
    }
}