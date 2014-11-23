# Fallback message strings in en-US
DATA localizedData
{
# same as culture = "en-US"
ConvertFrom-StringData @'    
    GettingFilterInstance=Getting Filter Instance named {0}.
    FilterInstanceFound=Filter Instance named {0} is found.
    FilterInstanceNotFound=Filter Instance named {0} not found.
    CreatingEventFilter=Creating Filter Instance named {0} with query {1}.
    CreatedEventFilter=Created Filter Instance named {0}.
    RemovingEventFilter=Removing Filter Instance named {0}.
    RemovedEventFilter=Removed Filter Instance named {0}.
    FilterInstanceFoundNoAction=Filter Instance named {0} already exists. No action needed.
    FilterInstanceNotFoundShouldCreate=Filter Instance named {0} does not exist. It will be created.
    FilterInstanceFoundShouldDelete=Filter Instance named {0} exists. This will be removed.
    FilterInstanceNotFoundNoAction=Filter Instance named {0} not found. No action needed.
'@
}

if (Test-Path $PSScriptRoot\en-us)
{
    Import-LocalizedData LocalizedData -filename WMIEventFilter.psd1
}

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

    Write-Verbose ($localizedData.GettingFilterInstance -f $Name)
    $EventFilter = Get-CimInstance -Namespace 'root\subscription' -Class __EventFilter -Filter "Name='$Name'"
    if ($EventFilter) {
        Write-Verbose ($localizedData.FilterInstanceFound -f $Name)
        $Configuration.Add('Ensure','Present')
        $Configuration.Add('Query',$EventFilter.Query)
    } else {
        Write-Verbose ($localizedData.FilterInstanceNotFound -f $Name)
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
        Write-Verbose ($localizedData.CreatingEventFilter -f $Name, $Query)
        New-CimInstance -ClassName '__EventFilter' -Namespace 'root\subscription' -Property @{
            Name = $Name
            EventNamespace = $EventNamespace
            Query = $Query
            QueryLanguage = 'WQL'
        }
        Write-Verbose ($localizedData.CreatedEventFilter -f $Name)
    } else {
        Write-Verbose ($localizedData.RemovingEventFilter -f $Name)
        Remove-CimInstance -Namespace 'root\subscription' -Query "Select * FROM __EventFilter WHERE Name='${Name}'"
        Write-Verbose ($localizedData.RemovedEventFilter -f $Name)
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

    Write-Verbose ($localizedData.GettingFilterInstance -f $Name)
    $EventFilter = Get-CimInstance -Namespace 'root\subscription' -Class __EventFilter -Filter "Name='$Name'"

    if ($Ensure -eq 'Present') {
        if ($EventFilter) {
            Write-Verbose ($localizedData.FilterInstanceFoundNoAction -f $Name)
            return $true
        } else {
            Write-Verbose ($localizedData.FilterInstanceNotFoundShouldCreate -f $Name)
            return $false
        }
    } else {
        if ($EventFilter) {
            Write-Verbose ($localizedData.FilterInstanceFoundShouldDelete -f $Name)
            return $false
        } else {
            Write-Verbose ($localizedData.FilterInstanceNotFoundNoAction -f $Name)
            return $true
        }
    }
}