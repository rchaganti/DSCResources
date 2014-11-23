# Fallback message strings in en-US
DATA localizedData
{
# same as culture = "en-US"
ConvertFrom-StringData @'    
    GettingConsumerInstance=Getting Consumer Instance named {0}.
    ConsumerInstanceFound=Consumer Instance named {0} is found.
    ConsumerInstanceNotFound=Getting Consumer Instance named {0} not found.
    CreatingConsumerInstance=Creating Consumer Instance named {0}.
    NotAbsolutePath=ExecutablePath value {0} provided is not absolte path.
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
    Import-LocalizedData LocalizedData -filename WMICommandLineConsumer.psd1
}

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
    
    Write-Verbose ($localizedData.GettingConsumerInstance -f $Name)
    $ScriptConsumer = Get-CimInstance -Namespace 'root\subscription' -Query "SELECT * FROM CommandLineEventConsumer  WHERE Name='$Name'"
    
    if ($ScriptConsumer) {
        Write-Verbose ($localizedData.ConsumerInstanceFound -f $Name)
        $Configuration.Add('Ensure','Present')
        $Configuration.Add('ExecutablePath',$CommandLineEventConsumer.ExecutablePath)
        $Configuration.Add('WorkingDirectory',$CommandLineEventConsumer.WorkingDirectory)
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
        Write-Verbose ($localizedData.CreatingConsumerInstance -f $Name)
        
        $Properties = @{
            Name = $Name
            CommandLineTemplate = $CommandLineTemplate
        }

        if ($ExecutablePath) {
            if (-not [System.IO.Path]::IsPathRooted($ExecutablePath)) {
                Throw ($localizedData.NotAbsolutePath -f $ExecutablePath)
            } else {
                $Properties.Add('ExecutablePath', $ExecutablePath)
            }
        }

        if ($WorkingDirectory) {
            $Properties.Add('WorkingDirectory',$WorkingDirectory)
        }

        New-CimInstance -Namespace 'root\subscription' -ClassName 'CommandLineEventConsumer' -Property $Properties
        Write-Verbose ($localizedData.CreatedConsumerInstance -f $Name)
    } else {
        Write-Verbose ($localizedData.RemovingConsumerInstance -f $Name)
        Remove-CimInstance -Namespace 'root\subscription' -Query "SELECT * FROM CommandLineEventConsumer WHERE Name='$Name'"
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

    Write-Verbose ($localizedData.GettingConsumerInstance -f $Name)
    $CommandLineEventConsumer = Get-CimInstance -Namespace 'root\subscription' -Query "SELECT * FROM CommandLineEventConsumer WHERE Name='$Name'"
    
    if ($Ensure -eq 'Present') {
        if ($CommandLineEventConsumer) {
            Write-Verbose ($localizedData.ConsumerExistsNoAction -f $Name)
            return $true
        } else {
            Write-Verbose ($localizedData.ConsumerDoesNotExistShouldCreate -f $Name)
            return $false
        }
    } else {
        if ($CommandLineEventConsumer) {
            Write-Verbose ($localizedData.ConsumerExistsShouldRemove -f $Name)
            return $false
        } else {
            Write-Verbose ($localizedData.ConsumerDoesNotExistNoAction -f $Name)
            return $true
        }
    }
}