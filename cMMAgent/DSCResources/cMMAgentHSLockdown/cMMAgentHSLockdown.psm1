function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [System.String[]]
        $Allowed,

        [System.String[]]
        $Denied,

        [parameter(Mandatory = $true)]
        [ValidateSet("Add", "Remove")]
        [System.String]
        $Action,

        [parameter()]
        [bool]
        $RestartService
    )

    begin {
        $MMAReg = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup\"
        $MMAgentInstallDirectory = $MMAReg.InstallDirectory

        Write-Verbose "Checking HSLockdown permissions"

        $Allowed = @()
        $Denied = @()
    }

    process {
        try {
            $configuration = & "$MMAgentInstallDirectory\HSLockdown.exe" /L
            $Permission = $null
            $configuration | ? { [string]::IsNullOrWhiteSpace($_) -eq $false } | Foreach-Object {
                if ($_.trim() -eq "Allowed:") {
                    $permission = "Allowed"
                    return
                }
                if ($_.trim() -eq "Denied:") {
                    $permission = "Denied"
                    return
                }
                if ($permission -eq "Allowed") {
                    $Allowed += $_.trim()
                }
                if ($permission -eq "Denied") {
                    $Denied += $_.trim()
                }
            }

            return @{
                Allowed = $Allowed
                Denied  = $Denied
                Action  = $Action
            }
        }
        catch {
            $exception = $_
            Write-Verbose "Error occured $($exception.message)"
            while ($exception.InnerException -ne $null) {
                $exception = $exception.InnerException
                Write-Verbose "$($exception.message)"
            }
            return @{
                Allowed = $Allowed
                Denied  = $Denied
                Action  = $Action
            }
        }
    }
}
function Set-TargetResource {
    [CmdletBinding()]
    param
    (
        [parameter()]
        [System.String[]]
        $Allowed,

        [parameter()]
        [System.String[]]
        $Denied,

        [parameter(Mandatory = $true)]
        [ValidateSet("Add", "Remove")]
        [System.String]
        $Action,

        [parameter()]
        [bool]
        $RestartService
    )

    begin {
        $MMAReg = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup\"
        $MMAgentInstallDirectory = $MMAReg.InstallDirectory
    }

    process {
        try {
            if ($Action -eq 'Add') {
                $Allowed | Foreach-Object {
                    Write-Verbose "Adding $_ to Allowed"
                    & "$MMAgentInstallDirectory\HSLockdown.exe" /A $_ | Out-Null
                }

                $Denied | Foreach-Object {
                    Write-Verbose "Adding $_ to Denied"
                    & "$MMAgentInstallDirectory\HSLockdown.exe" /D $_ | Out-Null
                }
            }
            else {
                $Allowed | Foreach-Object {
                    Write-Verbose "Removing $_"
                    & "$MMAgentInstallDirectory\HSLockdown.exe" /R $_ | Out-Null
                }

                $Denied | Foreach-Object {
                    Write-Verbose "Removing $_"
                    & "$MMAgentInstallDirectory\HSLockdown.exe" /R $_ | Out-Null
                }
            }

            if($RestartService) {
                Restart-Service HealthService -Force
            }
        }
        catch {
            $exception = $_
            Write-Verbose "Error occured $($exception.message)"
            while ($exception.InnerException -ne $null) {
                $exception = $exception.InnerException
                Write-Verbose "$($exception.message)"
            }
        }
    }
}
function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter()]
        [System.String[]]
        $Allowed,

        [parameter()]
        [System.String[]]
        $Denied,

        [parameter(Mandatory = $true)]
        [ValidateSet("Add", "Remove")]
        [System.String]
        $Action,

        [parameter()]
        [bool]
        $RestartService
    )

    $Result = Get-TargetResource @PSBoundParameters

    if ((($Result.Allowed -ne $Allowed -or $_.Denied -ne $Denied) -and $Result.Action -eq "Add") -or ($Action -eq "Remove" -and ((Compare-Object $Allowed $Result.Allowed -IncludeEqual -ExcludeDifferent) -or (Compare-Object $Denied $Result.Denied -IncludeEqual -ExcludeDifferent)))) {
        return $false
    }
    else {
        return $true
    }
}

Export-ModuleMember -Function *-TargetResource
