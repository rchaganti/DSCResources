function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $CertificateThumbprint,

        [parameter()]
        [bool]
        $RestartService
    )

    Write-Verbose "Checking SCOM Certificate Configuration"

    try
    {
        $CurrentCertThumbprint = (get-item "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Machine Settings").GetValue("ChannelCertificateHash")
        $CurrentCertSerialNumber = (get-item "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Machine Settings").GetValue("ChannelCertificateSerialNumber")
        
        $SerialNumber = $CurrentCertSerialNumber | ConvertFrom-BinarySerialNumber

        $Cert = Get-Childitem "Cert:\LocalMachine\My" | ? { $_.Thumbprint -eq $CurrentCertThumbprint }

        return @{
            SubjectName = $Cert.Subject
            CertificateThumbprint = $CurrentCertThumbprint
            SerialNumber          = $SerialNumber
            RestartService = $RestartService
        }
    }
    catch
    {
        $exception = $_
        Write-Verbose "Error occured $($exception.message)"
        while ($exception.InnerException -ne $null)
        {
            $exception = $exception.InnerException
            Write-Verbose "$($exception.message)"
        }
        return @{
            SubjectName = ""
            CertificateThumbprint = ""
            SerialNumber = ""
            RestartService = $RestartService
        }
    }
}
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $CertificateThumbprint,

        [parameter()]
        [bool]
        $RestartService
    )
    begin {
        $MMAgentRegPath = "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Machine Settings"
    }

        try
        {
            Write-Verbose "Assigning Certificate"
            $Cert = Get-Childitem "Cert:\LocalMachine\My" | ? { $_.Thumbprint -eq $CurrentCertThumbprint }
            New-ItemProperty -Path $MMAgentRegPath -PropertyType string -Name "ChannelCertificateHash" -Value $Cert.Thumbprint | out-null
            New-ItemProperty -Path $MMAgentRegPath -PropertyType binary -Name "ChannelCertificateSerialNumber" -Value ($Cert.SerialNumber | ConvertTo-BinarySerialNumber) | out-null

            if($RestartService) {
                Restart-Service HealthService -Force
            }
        }
        catch
        {
            $exception = $_
            Write-Verbose "Error occured $($exception.message)"
            while ($exception.InnerException -ne $null)
            {
                $exception = $exception.InnerException
                Write-Verbose "$($exception.message)"
            }
        }
}
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $CertificateThumbprint,

        [parameter()]
        [bool]
        $RestartService
    )

    $Result = Get-TargetResource @PSBoundParameters

    return ($Result.CertificateThumbprint -eq $CertificateThumbprint)
}

function Convert-BinToHex {
    param(
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [Byte[]]
        $Bin)

    if ($bin.Length -eq 1) {
        $bin = @($input)
    }
    $return = -join ($Bin |  foreach { "{0:X2}" -f $_ })
    Write-Output $return
}

function Convert-HexToBin {
    param(
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [string]
        $s)

    $return = @()

    for ($i = 0; $i -lt $s.Length ; $i += 2) {
        $return += [Byte]::Parse($s.Substring($i, 2), [System.Globalization.NumberStyles]::HexNumber)
    }

    Write-Output $return
}

function ConvertFrom-BinarySerialNumber {
    param(
        [parameter(Mandatory)]
        [Byte[]]
        $SerialNumber
    )

    process {
        $SerialNumberArray = ($SerialNumber | Convert-BinToHex) -split '' | ? { $_ }
        [Array]::reverse($SerialNumberArray)
        $SerialNumberString = ""
        $i = 0
        while ($i -lt $SerialNumberArray.Count) {
            $SerialNumberString += $SerialNumberArray[$i+1]
            $SerialNumberString += $SerialNumberArray[$i]
            $i = $i+2
        }

        return $SerialNumberString
    }
}

function ConvertTo-BinarySerialNumber {
    param(
        [parameter(Mandatory, ValueFromPipeline)]
        [string]
        $SerialNumber
    )

    process {
        $SerialNumberArray = ($SerialNumber) -split '' | ? { $_ }
        [Array]::reverse($SerialNumberArray)
        $SerialNumber = ""
        $i = 0
        while ($i -lt $SerialNumberArray.Count) {
            $SerialNumber += $SerialNumberArray[$i+1]
            $SerialNumber += $SerialNumberArray[$i]
            $i = $i+2
        }

        return $SerialNumber | Convert-HexToBin
    }
}

Export-ModuleMember -Function *-TargetResource

