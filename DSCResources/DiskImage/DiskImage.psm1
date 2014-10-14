Function Get-TargetResource {
    [OutputType([Hashtable])]
    param (
        [Parameter(Mandatory)]
        [string] $ImagePath,

        [Parameter(Mandatory)]
        [string] $DriveLetter,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [string] $Ensure = 'Present'
    )

    $Configuration = @{
        ImagePath = $ImagePath
        DriveLetter = $DriveLtter
    }

    $DiskImage = Get-DiskImage -ImagePath $ImagePath -ErrorAction Stop
    if ($DiskImage.Attached) {
        if (($DiskImage | Get-Volume).DriveLetter -eq $DriveLtter) {
            $Configuration.Add('Ensure','Present')
        } else {
            $Configuration.Add('Ensure','Absent')
        }
    }

    $Configuration
}

Function Set-TargetResource {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $ImagePath,

        [Parameter(Mandatory)]
        [string] $DriveLetter,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [string] $Ensure = 'Present'
    )

    $DriveLetter = $DriveLetter + ':'

    if ($Ensure -eq 'Present') {
        Write-Verbose "Mounting Disk image"
        $DiskImage = Mount-DiskImage -ImagePath $ImagePath -NoDriveLetter -PassThru -ErrorAction Stop | Get-Volume
        $DiskVolume = Get-CimInstance -ClassName Win32_Volume | Where-Object { $_.DeviceID -eq $DiskImage.ObjectId }

        Write-Verbose "Setting Drive Letter"
        Set-CimInstance -Property @{DriveLetter= $DriveLetter } -InputObject $DiskVolume -ErrorAction Stop
    } else {
        Write-Verbose "Dismounting disk image"
        Dismount-DiskImage -ImagePath $ImagePath
    }
}

Function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([Boolean])]
    param (
        [Parameter(Mandatory)]
        [ValidateScript(
            {   
                ([System.IO.Path]::GetExtension($_) -eq '.iso') -and (Test-Path $_)
            }
        )]
        [string] $ImagePath,

        [Parameter(Mandatory)]
        [ValidateScript({-not (Test-Path $_)})]
        [string] $DriveLetter,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [string] $Ensure = 'Present'
    )

    $DiskImage = Get-DiskImage -ImagePath $ImagePath -ErrorAction Stop
    if ($DiskImage.Attached) {
        if (($DiskImage | Get-Volume).DriveLetter -eq $DriveLetter) {
            $MountExists = $true
        } else {
            $MountExists = $false
        }
    }
    
    if ($MountExists) {
        if ($Ensure -eq 'Present') {
            Write-Verbose 'disk image is already mounted. No action needed'
            $true
        } else {
            Write-Verbose 'disk image is mounted while it should not'
            $false
        }
    } else {
        if ($Ensure -eq 'Absent') {
            Write-Verbose 'disk image is not mounted. No action needed'
            $true
        } else {
            Write-Verbose 'disk image is not mounted while it should'
            $false
        }
    }
}

Export-ModuleMember -Function *-TargetResource