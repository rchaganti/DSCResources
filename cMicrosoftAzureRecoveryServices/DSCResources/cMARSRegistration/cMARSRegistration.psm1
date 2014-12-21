# Fallback message strings in en-US
DATA localizedData
{
# same as culture = "en-US"
ConvertFrom-StringData @'
    AlreadyRegistered=Already Registered with an Azure Backup Vault.
    NotRegistered=Not registered with an Azure Backup Vault
    ProxySettingNotFound=Found no ProxySetting configuration.
    MSOnlineBackupNotFound=MSonlineBackup module not found.
    RegisterServer=Server will be registered with Azure Backup Vault.
    RegisteredServer=Server registration complete.
    AbsentNotImplemented=Absent not implemented. Please use cMARSAgentInstall to uninstall the agent.
    RegistrationExistsNoAction=Registration Already exists. No Action needed.
    RegistrationNotFoundShouldAdd=Registration does not exist. Server will be registered.
    RegistartionExistsShouldDelete=Registration already exists. It should be removed.
    RegistrationNotFoundNoAction=Registration does not exist. No action needed.
    AnErrorOccurred=An error occurred while verifying/updating proxy configuration: {0}.
    InnerException=Nested error trying to verifying/updating proxy configuration: {0}.
'@
}

if (Test-Path $PSScriptRoot\en-us)
{
    Import-LocalizedData LocalizedData -filename cMARSRegistration.psd1
}

function Get-TargetResource
{
    [OutputType([Hashtable])]
    param (
        [Parameter(Mandatory)]
        [String] $VaultCredential
    )

    $Configuration = @{
        VaultCredential = $VaultCredential
    }

    try {
        $env:PSModulePath += ";$([System.Environment]::GetEnvironmentVariable("PSModulePath","Machine"))"
        Import-Module -Name MSOnlineBackup    
    }
    
    catch {
        throw $localizedData.MSOnlineBackupNotFound
    }

    try {
        $RegistrationStatus = [Microsoft.Internal.CloudBackup.Client.Common.CBClientCommon]::GetMachineRegistrationStatus($true)
        if ($RegistrationStatus) {
            Write-Verbose $localizedData.AlreadyRegistered
            $Configuration.Add('Ensure','Present')
        } else {
            Write-Verbose $localizedData.NotRegistered
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
        [String] $VaultCredential,

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
        if ($Ensure -eq 'Present') {
            Write-Verbose $LocalizedData.RegisterServer
            Start-OBRegistration -VaultCredentials $VaultCredential -Confirm:$false
            Write-Verbose $LocalizedData.RegisteredServer
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
        [String] $VaultCredential,

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
        $RegistrationStatus = [Microsoft.Internal.CloudBackup.Client.Common.CBClientCommon]::GetMachineRegistrationStatus($true)
        
        if ($Ensure -eq 'Present') {
            if ($RegistrationStatus) {
                Write-Verbose ($localizedData.RegistrationExistsNoAction)
                return $true
            } else {
                Write-Verbose ($localizedData.RegistrationNotFoundShouldAdd)
                return $false
            }
        } else {
            if ($RegistrationStatus) {
                Write-Verbose ($localizedData.RegistartionExistsShouldDelete)
                return $false
            } else {
                Write-Verbose ($localizedData.RegistrationNotFoundNoAction)
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