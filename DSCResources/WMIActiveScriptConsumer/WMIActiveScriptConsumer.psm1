# Fallback message strings in en-US
DATA localizedData
{
# same as culture = "en-US"
ConvertFrom-StringData @'    
    GettingConsumerInstance=Getting Consumer Instance named {0}.
    ConsumerInstanceFound=Consumer Instance named {0} is found.
    ConsumerInstanceNotFound=Getting Consumer Instance named {0} not found.
    CreatingConsumerInstance=Creating Consumer Instance named {0}.
    NotAbsolutePath=ScriptFileName value {0} provided is not absolte path.
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
    Import-LocalizedData LocalizedData -filename WMIActiveScriptConsumer.psd1
}

function Get-TargetResource
{
    [CmdletBinding(DefaultParameterSetName='ScriptText')]
    [OutputType([Hashtable])]
    param (
        [Parameter(Mandatory, ParameterSetName='ScriptText')]
        [Parameter(Mandatory, ParameterSetName='ScriptFile')]
        [string] $Name,

        [Parameter(Mandatory, ParameterSetName='ScriptFile')]
        [String] $ScriptFileName,

        [Parameter(Mandatory, ParameterSetName='ScriptText')]
        [String] $ScriptText
    )

    $Configuration = @{
        Name = $Name
    }

    if ($PSCmdlet.ParameterSetName -eq 'ScriptText') {
        $Configuration.Add('ScriptText', $ScriptText)
    } else {
        $Configuration.Add('ScriptFileName', $ScriptFileName)
    }

    Write-Verbose ($localizedData.GettingConsumerInstance -f $Name)
    $ActiveScriptEventConsumer = Get-CimInstance -Namespace 'root\subscription' -Query "SELECT * FROM ActiveScriptEventConsumer WHERE Name='$Name'"
    
    if ($ActiveScriptEventConsumer) {
        Write-Verbose ($localizedData.ConsumerInstanceFound -f $Name)
        $Configuration.Add('Ensure','Present')
        $Configuration.Add('MaximumQueueSize',$ActiveScriptEventConsumer.MaximumQueueSize)
        $Configuration.Add('MachineName',$ActiveScriptEventConsumer.MachineName)
        $Configuration.Add('CreatorSID',$ActiveScriptEventConsumer.CreatorSID)
    } else {
        Write-Verbose ($localizedData.ConsumerInstanceNotFound -f $Name)
        $Configuration.Add('Ensure','Absent')
    }

    return $Configuration
}

function Set-TargetResource
{
    [CmdletBinding(DefaultParameterSetName='ScriptText')]
    param (
        [Parameter(Mandatory, ParameterSetName='ScriptText')]
        [Parameter(Mandatory, ParameterSetName='ScriptFile')]
        [string] $Name,

        [Parameter(Mandatory, ParameterSetName='ScriptFile')]
        [String] $ScriptFileName,

        [Parameter(ParameterSetName='ScriptFile')]
        [Parameter(ParameterSetName='ScriptText')]
        [String] $ScriptingEngine='VBScript',

        [Parameter(Mandatory,ParameterSetName='ScriptText')]
        [String] $ScriptText,

        [Parameter(ParameterSetName='ScriptFile')]
        [Parameter(ParameterSetName='ScriptText')]
        [uint32] $MaximumQueueSize,

        [Parameter(ParameterSetName='ScriptFile')]
        [Parameter(ParameterSetName='ScriptText')]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )

    if ($Ensure -eq 'Present') {
        Write-Verbose ($localizedData.CreatingConsumerInstance -f $Name)

        $Properties = @{
            Name = $Name
            ScriptingEngine = $ScriptingEngine
        }

        if ($PSCmdlet.ParameterSetName -eq 'ScriptFile') {        
            if (-not [System.IO.Path]::IsPathRooted($ScriptFileName)) {
                Throw ($localizedData.NotAbsolutePath -f $ScriptFileName)
            }
            $Properties.Add('ScriptFileName', $ScriptFileName)
        } else {
            $Properties.Add('ScriptText', $ScriptText)
        }

        if ($MaximumQueueSize) {
            $Properties.Add('MaximumQueueSize',$MaximumQueueSize)
        }
        
        New-CimInstance -Namespace 'root\subscription' -ClassName 'ActiveScriptEventConsumer' -Property $Properties
        Write-Verbose ($localizedData.CreatedConsumerInstance -f $Name)
    } else {
        Write-Verbose ($localizedData.RemovingConsumerInstance -f $Name)
        Remove-CimInstance -Namespace 'root\subscription' -Query "SELECT * FROM ActiveScriptEventConsumer WHERE Name='$Name'"
        Write-Verbose ($localizedData.RemovedConsumerInstance -f $Name)
    }
}

function Test-TargetResource
{
    [CmdletBinding(DefaultParameterSetName='ScriptText')]
    [OutputType([Bool])]
    param (
        [Parameter(Mandatory, ParameterSetName='ScriptText')]
        [Parameter(Mandatory, ParameterSetName='ScriptFile')]
        [string] $Name,

        [Parameter(Mandatory, ParameterSetName='ScriptFile')]
        [String] $ScriptFileName,

        [Parameter(ParameterSetName='ScriptFile')]
        [Parameter(ParameterSetName='ScriptText')]
        [String] $ScriptingEngine='VBScript',

        [Parameter(Mandatory,ParameterSetName='ScriptText')]
        [String] $ScriptText,

        [Parameter(ParameterSetName='ScriptFile')]
        [Parameter(ParameterSetName='ScriptText')]
        [uint32] $MaximumQueueSize,

        [Parameter()]
        [Parameter(ParameterSetName='ScriptFile')]
        [Parameter(ParameterSetName='ScriptText')]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )

    Write-Verbose ($localizedData.GettingConsumerInstance -f $Name)
    $ActiveScriptEventConsumer = Get-CimInstance -Namespace 'root\subscription' -Query "SELECT * FROM ActiveScriptEventConsumer WHERE Name='$Name'"
    
    if ($Ensure -eq 'Present') {
        if ($ActiveScriptEventConsumer) {
            Write-Verbose ($localizedData.ConsumerExistsNoAction -f $Name)
            return $true
        } else {
            Write-Verbose ($localizedData.ConsumerDoesNotExistShouldCreate -f $Name)
            return $false
        }
    } else {
        if ($ActiveScriptEventConsumer) {
            Write-Verbose ($localizedData.ConsumerExistsShouldRemove -f $Name)
            return $false
        } else {
            Write-Verbose ($localizedData.ConsumerDoesNotExistNoAction -f $Name)
            return $true
        }
    }
}