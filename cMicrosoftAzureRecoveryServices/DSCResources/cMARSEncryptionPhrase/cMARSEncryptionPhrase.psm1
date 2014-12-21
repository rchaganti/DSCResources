# Fallback message strings in en-US
DATA localizedData
{
# same as culture = "en-US"
ConvertFrom-StringData @'
    AlreadySet=An encryption passphrase is already set.
    NotSet=An encryption passphrase is not set.
    SetPassPhrase=Setting encryption pass phrase.
    PassPhraseSetComplete=Setting encryption pass phrase complete.
    AbsentNotImplemented=Absent not implemented. Please use cMARSAgentInstall to uninstall the agent.
    ForceFound=Force property found. Pass phrase will be updated.
    PassPhraseSetNoAction=Pass phrase already set. No action needed.
    PassPhraseNotSetShouldAdd=Pass phrase not set. It will be added.
    PassPhraseSetShouldRemove=Pass phrase set. It will be removed.
    PassPhraseNotSetNoAction=Pass phrase not set. No action needed.
    AnErrorOccurred=An error occurred while verifying/updating proxy configuration: {0}.
    InnerException=Nested error trying to verifying/updating proxy configuration: {0}.
'@
}

if (Test-Path $PSScriptRoot\en-us)
{
    Import-LocalizedData LocalizedData -filename cMARSEncryptionPhrase.psd1
}

function Get-TargetResource
{
    [OutputType([Hashtable])]
    param (
        [Parameter(Mandatory)]
        [String] $EncryptionPassPhrase
    )

    $Configuration = @{
        EncryptionPassPhrase = $EncryptionPassPhrase
    }

    try {
        $env:PSModulePath += ";$([System.Environment]::GetEnvironmentVariable("PSModulePath","Machine"))"
        Import-Module -Name MSOnlineBackup    
    }
    
    catch {
        throw $localizedData.MSOnlineBackupNotFound
    }

    try {
        $KeyStatus = (Get-OBMachineSetting | Select -ExpandProperty EncryptionSetting).EncryptionKeyStatus
        if ($KeyStatus -eq 'Set') {
            Write-Verbose $localizedData.AlreadySet
            $Configuration.Add('Ensure','Present')
        } else {
            Write-Verbose $localizedData.NotSet
            $Configuration.Add('Ensure','Absent')
        }

        return $Configuration
    }

    catch {
        $exception = $_    
        Write-Verbose ($LocalizedData.AnErrorOccurred -f $exception.message)
        while ($exception.InnerException -ne $null)
        {
            $exception = $exception.InnerException
            Write-Verbose ($LocalizedData.InnerException -f $exception.message)
        }        
    }
}

function Set-TargetResource
{
    param (
        [Parameter(Mandatory)]
        [String] $EncryptionPassPhrase = 'Dell12345678901234',

        [Parameter()]
        [Bool] $Force,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String] $Ensure = 'Present'
    )

    try {
        $env:PSModulePath += ";$([System.Environment]::GetEnvironmentVariable("PSModulePath","Machine"))"
        Import-Module -Name MSOnlineBackup    
    }
    
    catch {
        throw $localizedData.MSOnlineBackupNotFound
    }

    try {
        if (($Ensure -eq 'Present') -or $Force) {
            Write-Verbose $LocalizedData.SetPassPhrase
            $SecureString = ConvertTo-SecureString -String $EncryptionPassPhrase -AsPlainText -Force
            Set-OBMachineSetting -EncryptionPassphrase $SecureString
            Write-Verbose $LocalizedData.PassPhraseSetComplete
        } else {
            Write-Verbose $localizedData.AbsentNotImplemented
        }
    }
    catch {
        $exception = $_    
        Write-Verbose ($LocalizedData.AnErrorOccurred -f $exception.message)
        while ($exception.InnerException -ne $null)
        {
            $exception = $exception.InnerException
            Write-Verbose ($LocalizedData.InnerException -f $exception.message)
        }
    }
}

function Test-TargetResource
{
    [OutputType([boolean])]
    param (
        [Parameter(Mandatory)]
        [String] $EncryptionPassPhrase,

        [Parameter()]
        [Bool] $Force,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String] $Ensure = 'Present'
    )

    try {
        $env:PSModulePath += ";$([System.Environment]::GetEnvironmentVariable("PSModulePath","Machine"))"
        Import-Module -Name MSOnlineBackup    
    }
    
    catch {
        throw $localizedData.MSOnlineBackupNotFound
    }

    try {
        $KeyStatus = (Get-OBMachineSetting | Select -ExpandProperty EncryptionSetting).EncryptionKeyStatus
        if ($Force) {
            Write-Verbose $localizedData.ForceFound
            return $false
        } elseif ($Ensure -eq 'Present') {
            if ($KeyStatus -eq 'Set') {
                Write-Verbose ($localizedData.PassPhraseSetNoAction)
                return $true
            } else {
                Write-Verbose ($localizedData.PassPhraseNotSetShouldAdd)
                return $false
            }
        } else {
            if ($KeyStatus -eq 'Set') {
                Write-Verbose ($localizedData.PassPhraseSetShouldRemove)
                return $false
            } else {
                Write-Verbose ($localizedData.PassPhraseNotSetNoAction)
                return $true
            }
        }
    }

    catch {
        $exception = $_
        Write-Verbose ($LocalizedData.AnErrorOccurred -f $exception.message)
        while ($exception.InnerException -ne $null)
        {
            $exception = $exception.InnerException
            Write-Verbose ($LocalizedData.InnerException -f $exception.message)
        }
    }
}