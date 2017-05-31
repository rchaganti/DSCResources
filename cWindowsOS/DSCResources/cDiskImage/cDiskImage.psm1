# Fallback message strings in en-US
DATA localizedData
{
# same as culture = "en-US"
ConvertFrom-StringData @'    
    GetDiskImage=Getting Disk Image Instance at path {0}.
    DiskImageMounted=Disk image at the path {0} is mounted.
    DiskImageNotMounted=Disk image at the path {0} is not mounted.
    MountingDiskImage=Mounting disk image at path {0}.
    MountedDiskImage=Disk image at path {0} is mounted.
    SetDriveLetetr=Setting Drive letter of the mounted image to {0}.
    DriverLetterSet=Drive letter of the mounted image set to {0}.
    DisMountingDiskImage=Dismounting disk image at path {0}.
    DismountedDiskImage=Disk image at path {0} is dismounted.
    MountExistsWithDriveLetter=Disk image mount exists with same drive letter as requested.
    MountExistsWithDifferentDriveLetter=Disk image mount exists with different drive letter than requested.
    MountExistsNoAction=Disk image mount for {0} already exists. No action needed.
    MountDoesNotExistShouldCreate=Disk image mount for {0} does not exist. It will be mounted.
    MountExistsShouldRemove=Disk image mount for {0} exists. It will be dismounted.
    MountDoesNotExistNoAction=Disk image mount for {0} does not exist. No action needed.
'@
}

if (Test-Path $PSScriptRoot\en-us)
{
    Import-LocalizedData LocalizedData -filename cDiskImage.psd1
}

Function Get-TargetResource {
    [OutputType([Hashtable])]
    param (
        [Parameter(Mandatory)]
        [ValidateScript(
            {
                $extension = [System.IO.Path]::GetExtension($_)
                if (($extension -eq '.iso' -or $extension -eq '.vhd' -or $extension -eq '.vhdx') -and (Test-Path $_)) {
                    $true
                } else {
                    $false
                }
            }
        )]
        [string] $ImagePath,

        [Parameter(Mandatory)]
        [string] $DriveLetter,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [string] $Ensure = 'Present'
    )

    $Configuration = @{
        ImagePath = $ImagePath
        DriveLetter = $DriveLetter
    }

    Write-Verbose -Message ($localizedData.GetDiskImage -f $ImagePath)
    $DiskImage = Get-DiskImage -ImagePath $ImagePath
    if ($DiskImage.Attached) {
        if (($DiskImage | Get-Volume).DriveLetter -eq $DriveLetter) {
            Write-Verbose -Message ($localizedData.DiskImageMounted -f $ImagePath)
            $Configuration.Add('Ensure','Present')
        } else {
            Write-Verbose -Message ($localizedData.DiskImageNotMounted -f $ImagePath)
            $Configuration.Add('Ensure','Absent')
        }
    }

    $Configuration
}


Function Set-TargetResource {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateScript(
            {
                $extension = [System.IO.Path]::GetExtension($_)
                if (($extension -eq '.iso' -or $extension -eq '.vhd' -or $extension -eq '.vhdx') -and (Test-Path $_)) {
                    $true
                } else {
                    $false
                }
            }
        )]
        [string] $ImagePath,

        [Parameter(Mandatory)]
        [string] $DriveLetter,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [string] $Ensure = 'Present'
    )

    $DriveLetter = $DriveLetter + ':'

    if ($Ensure -eq 'Present') {
        Write-Verbose -Message ($localizedData.MountingDiskImage -f $ImagePath)
        $DiskImage = Mount-DiskImage -ImagePath $ImagePath -NoDriveLetter -PassThru | Get-Volume
        Write-Verbose -Message ($localizedData.MountedDiskImage -f $ImagePath)
        $DiskVolume = Get-CimInstance -ClassName Win32_Volume | Where-Object { $_.DeviceID -eq $DiskImage.ObjectId }

        Write-Verbose -Message ($localizedData.SetDriveLetter -f $DriveLetter)
        Set-CimInstance -Property @{DriveLetter= $DriveLetter } -InputObject $DiskVolume
        Write-Verbose -Message ($localizedData.DriveLetterSet -f $DriveLetter)
    } else {
        Write-Verbose -Message ($localizedData.DisMountingDiskImage -f $DiskImage)
        Dismount-DiskImage -ImagePath $ImagePath
        Write-Verbose -Message ($localizedData.DismountedDiskImage -f $DiskImage)
    }
}

Function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([Boolean])]
    param (
        [Parameter(Mandatory)]
        [ValidateScript(
            {
                $extension = [System.IO.Path]::GetExtension($_)
                if (($extension -eq '.iso' -or $extension -eq '.vhd' -or $extension -eq '.vhdx') -and (Test-Path $_)) {
                    $true
                } else {
                    $false
                }
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

    Write-Verbose -Message ($localizedData.GetDiskImage -f $ImagePath)
    $DiskImage = Get-DiskImage -ImagePath $ImagePath
    if ($DiskImage.Attached) {
        if (($DiskImage | Get-Volume).DriveLetter -eq $DriveLetter) {
            Write-Verbose -Message ($localizedData.MountExistsWithDriveLetter)
            $MountExists = $true
        } else {
            Write-Verbose -Message ($localizedData.MountExistsWithDifferentDriveLetter)
            $MountExists = $false
        }
    }
    
    if ($MountExists) {
        if ($Ensure -eq 'Present') {
            Write-Verbose -Message ($localizedData.MountExistsNoAction -f $ImagePath)
            $true
        } else {
            Write-Verbose -Message ($localizedData.MountDoesNotExistShouldCreate -f $ImagePath)
            $false
        }
    } else {
        if ($Ensure -eq 'Absent') {
            Write-Verbose -Message ($localizedData.MountExistsShouldRemove -f $ImagePath)
            $true
        } else {
            Write-Verbose -Message ($localizedData.MountDoesNotExistNoAction -f $ImagePath)
            $false
        }
    }
}

Export-ModuleMember -Function *-TargetResource