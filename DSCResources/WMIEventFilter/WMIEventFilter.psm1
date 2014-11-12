function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param (
        [Parameter(Mandatory)]
        [String] $Name,

        [Parameter(Mandatory)]
        [String] $Query,

        [Parameter()]
        [String] $EventNamespace='root\cimv2'
    )

    $Configuration = @{
        Name = $Name
        EventNamespace = $EventNamespace
    }

    $EventFilter = Get-CimInstance -Namespace 'root\subscription' -Class __EventFilter -Filter "Name='$Name'"
    if ($EventFilter) {
        $Configuration.Add('Ensure','Present')
        $Configuration.Add('Query',$EventFilter.Query)
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
        [String] $Name,

        [Parameter(Mandatory)]
        [String] $Query,

        [Parameter()]
        [String] $EventNamespace='root\cimv2',
        
        [Parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )

    if ($Ensure -eq 'Present') {
        Write-Verbose "Creating a new event filter named ${Name} in the root\subscription with ${query}"
        New-CimInstance -ClassName '__EventFilter' -Namespace 'root\subscription' -Property @{
            Name = $Name
            EventNamespace = $EventNamespace
            Query = $Query
            QueryLanguage = 'WQL'
        }
    } else {
        Write-Verbose "Removing Event filter named ${Name} from the namespace root\subscription"
        Remove-CimInstance -Namespace 'root\subscription' -Query "Select * FROM __EventFilter WHERE Name='${Name}'"
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([boolean])]
    param (
        [Parameter(Mandatory)]
        [String] $Name,

        [Parameter(Mandatory)]
        [String] $Query,

        [Parameter()]
        [String] $EventNamespace='root\cimv2',
        
        [Parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )

    $EventFilter = Get-CimInstance -Namespace 'root\subscription' -Class __EventFilter -Filter "Name='$Name'"

    if ($Ensure -eq 'Present') {
        if ($EventFilter) {
            Write-Verbose "Event filter with name ${Name} in the namespace root\subscription already exists. No action needed"
            return $true
        } else {
            Write-Verbose "Event filter with name ${Name} in the namespace root\subscription does not exist. It will be created"
            return $false
        }
    } else {
        if ($EventFilter) {
            Write-Verbose "Event filter with name ${Name} in the namespace root\subscription exists. It will be removed"
            return $false
        } else {
            Write-Verbose "Event filter with name ${Name} in the namespace root\subscription does not exist. No action needed"
            return $true
        }
    }
}