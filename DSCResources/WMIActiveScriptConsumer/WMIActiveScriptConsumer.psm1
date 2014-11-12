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

    $ActiveScriptEventConsumer = Get-CimInstance -Namespace 'root\subscription' -Query "SELECT * FROM ActiveScriptEventConsumer WHERE Name='$Name'"
    if ($ScriptConsumer) {
        $Configuration.Add('Ensure','Present')
        $Configuration.Add('MaximumQueueSize',$ActiveScriptEventConsumer.MaximumQueueSize)
        $Configuration.Add('MachineName',$ActiveScriptEventConsumer.MachineName)
        $Configuration.Add('CreatorSID',$ActiveScriptEventConsumer.CreatorSID)
    } else {
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
        Write-Verbose "Creating a new Active Script Consumer instance with name ${Name}"

        $Properties = @{
            Name = $Name
            ScriptingEngine = $ScriptingEngine
        }

        if ($PSCmdlet.ParameterSetName -eq 'ScriptFile') {        
            if (-not [System.IO.Path]::IsPathRooted($ScriptFileName)) {
                Throw "${ScriptFileName} is relative and cannot be processed"
            }
            $Properties.Add('ScriptFileName', $ScriptFileName)
        } else {
            $Properties.Add('ScriptText', $ScriptText)
        }

        if ($MaximumQueueSize) {
            $Properties.Add('MaximumQueueSize',$MaximumQueueSize)
        }

        New-CimInstance -Namespace 'root\subscription' -ClassName 'ActiveScriptEventConsumer' -Property $Properties
    } else {
        Write-Verbose "Removing an Active Script Consumer instance with name ${Name}"
        Remove-CimInstance -Namespace 'root\subscription' -Query "SELECT * FROM ActiveScriptEventConsumer WHERE Name='$Name'"
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

    $ActiveScriptEventConsumer = Get-CimInstance -Namespace 'root\subscription' -Query "SELECT * FROM ActiveScriptEventConsumer WHERE Name='$Name'"
    
    if ($Ensure -eq 'Present') {
        if ($ActiveScriptEventConsumer) {
            Write-Verbose "Active Script consumer with the name ${Name} already exists. No action needed"
            return $true
        } else {
            Write-Verbose "Active Script consumer with the name ${Name} does not exist. It will be created"
            return $false
        }
    } else {
        if ($ActiveScriptEventConsumer) {
            Write-Verbose "Active Script consumer with the name ${Name} already exists. It will be removed"
            return $false
        } else {
            Write-Verbose "Active Script consumer with the name ${Name} does not exist. No action needed"
            return $true
        }
    }
}