function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    $Configuration = @{
        Name = $Name
    }

    try
    {
        if ($vsCodeInstall = Get-VSCodeInstall)
        {
            if ([version] $vsCodeInstall.DisplayVersion -ge [version]'1.2.0')
            {
                Write-Verbose "Getting current list of installed extensions."
                $installedExtensions = Get-InstalledExtension
                if ($installedExtensions.Name -contains $Name)
                {
                    Write-Verbose -Message "${Name} extension is installed."
                    $Configuration.Add('Ensure','Present')
                    $Configuration
                }
                else
                {
                    Write-Verbose -Message "${Name} extension is not installed."
                    $Configuration.Add('Ensure','Absent')
                    $Configuration
                }
            }
            else
            {
                throw 'VS Code version must be at least 1.2.0'
            }
        }
        else 
        {
            Write-Verbose 'VS Code install not found. Get DSC method will be skipped.'
        }
    }

    catch
    {
        Write-Verbose "Error occured while executing Get-TargetResource function."
        Write-Error $_
    }
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present"
    )

    try
    {
        if ($vsCodeInstall = Get-VSCodeInstall)
        {
            if ($Ensure -eq 'Present')
            {
                try
                {
                    Write-Verbose -Message "Installing ${Name} extension ..."
                    cmd.exe /c "$($vsCodeInstall.InstallLocation)\bin\code.cmd" --install-extension ${Name}
                    if ((Get-InstalledExtension).Name -contains $Name)
                    {
                        Write-Verbose -Message "Extension ${Name} install complete. Restart VS code if open."
                    }
                    else
                    {
                        throw 'Extension install failed'
                    }
                }
                catch
                {
                    Write-Verbose "Error occured while installing extension in Set-TargetResource function."
                    Write-Error $_
                }
            }
            else
            {
                try
                {
                    Write-Verbose -Message "Uninstalling ${Name} extension ..."
                    cmd.exe /c "$($vsCodeInstall.InstallLocation)\bin\code.cmd" --uninstall-extension ${Name}
                    if ((Get-InstalledExtension).Name -contains $Name)
                    {
                        
                        throw 'Extension uninstall failed'
                    }
                    else
                    {
                        Write-Verbose -Message "Extension ${Name} uninstall complete. Restart VS code if open."
                    }
                }
                catch
                {
                    Write-Verbose "Error occured while uninstalling extension in Set-TargetResource function."
                    Write-Error $_
                }
            }
        }
    }
    catch
    {
        Write-Verbose "Error occured while executing Set-TargetResource function."
        Write-Error $_
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
        $Name,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present"
    )

    try
    {
        if ($vsCodeInstall = Get-VSCodeInstall)
        {
            if ([version] $vsCodeInstall.DisplayVersion -ge [version]'1.2.0')
            {
                Write-Verbose -Message "VS Code version $($vsCodeInstall.DisplayVersion) installed."
                Write-Verbose -Message "Getting a list of installed extensions."
                $installedExtensions = Get-InstalledExtension
                Write-Verbose -Message "VS Code has $($installedExtensions.Count) extensions installed."
                if ($installedExtensions.Name -contains $Name)
                {
                    if ($Ensure -eq 'Present')
                    {
                        Write-Verbose -Message "Extension ${Name} is already installed. No action needed."
                        return $true
                    }
                    else
                    {
                        Write-Verbose -Message "Extension ${Name} is installed. It will be removed."
                        return $false
                    }
                }
                else
                {
                    if ($Ensure -eq 'Present')
                    {
                        Write-Verbose -Message "Extension ${Name} is not installed. It will be installed."
                        return $false
                    }
                    else
                    {
                        Write-Verbose -Message "Extension ${Name} is not installed. No action not needed."
                        return $true
                    }
                }
            }
            else
            {
                Write-Verbose 'VS Code install 1.2.0 not found. Set DSC method will be skipped.'
                return $true
            }
        }
        else
        {
            Write-Verbose 'VS Code install not found. Set DSC method will be skipped.'
            return $true
        }
    }
    
    catch
    {
        Write-Verbose "Error occured while executing Test-TargetResource function."
        Write-Error $_
        return $false
    }
}

Function Get-InstalledExtension
{
    [CmdletBinding()]
    param (
    )

    # Get installation location
    $vsCodeInstall = Get-VSCodeInstall
    
    if ($VSCodeInstall)
    {
        # Get list of extensions from VS Code
        $extensionOutput = cmd.exe /c "$($vsCodeInstall.InstallLocation)\bin\code.cmd" --list-extensions --show-versions

        # Build a list of extension objects
        $extensionList = $extensionOutput.Split("`n") | ForEach-Object {
            $parts = $_.Split("@")
            $extensionDetails = @{
                Name = $parts[0];
                Version = $parts[1]
            }
            $extension = New-Object -TypeName PsObject -Property $extensionDetails
            $extension
        }

        return $extensionList
    }
    else 
    {
        Write-Verbose 'VS Code install not found. Could not list extensions.'
    }
}

#Function Wait-ForExtensionInstall
#{
#    [CmdletBinding()]
#    param (
#        [String]
#        $Name,
#
#        [UInt64]
#        $RetryIntervalSec = 10,
#
#        [UInt32]
#        $RetryCount = 10
#    )
#    
#    $extensionInstalled = $false
#
#    for ($count = 0; $count -lt $RetryCount; $count++)
#    {
#        Write-Verbose "Retry count: $($count+1); waiting for $RetryIntervalSec seconds"
#        $installedExtensions = Get-InstalledExtension
#        if ($installedExtensions.Name -contains $Name)
#        {
#            $extensionInstalled = $true
#            break
#        }
#        else
#        {
#            Start-Sleep -Seconds $RetryIntervalSec
#        }
#    }
#
#    if (!$extensionInstalled)
#    {
#        throw "$Name extension installed failed"
#    }
#    else
#    {
#        return $extensionInstalled
#    }
#}

Function Get-VSCodeInstall
{
    # First try user based install of VS Code
    Write-Verbose 'Looking for VS Code user install.'
    
    $UninstallKey = 'HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\*'
    if (Test-Path $UninstallKey)
    {
        $products = Get-ItemProperty -Path $UninstallKey | Select-Object DisplayName, DisplayVersion, InstallLocation
        if ($products.DisplayName -like 'Microsoft Visual Studio Code*')
        {
            $product = $products.Where({$_.DisplayName -like 'Microsoft Visual Studio Code*'})
            Write-Verbose -Message "Found VS Code system based install in HKCU (InstallLocation: [$($product.InstallLocation)])."
            return $product
        }
    }
    else 
    {
        Write-Verbose 'Unable to find uninstall registry key for current user HKEY_CURRENT_USER, if VS Code was user installed add PsDscRunAsCredential property in DSC.'
    }

    Write-Verbose 'Looking for VS Code system install.'

    # Second try system based install of VS Code
    $UninstallKey = 'HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\*'
    $products = Get-ItemProperty -Path $UninstallKey | Select-Object DisplayName, DisplayVersion, InstallLocation
    if ($products.DisplayName -like 'Microsoft Visual Studio Code*')
    {
        $product = $products.Where({$_.DisplayName -like 'Microsoft Visual Studio Code*'})
        Write-Verbose -Message "Found VS Code system based install in HKLM (InstallLocation: [$($product.InstallLocation)])."
        return $product
    }

    Write-Verbose 'Unable to determine if VS Code is installed.' 
    Write-Verbose 'User or System based installs is only currently supported by this extension.'
}

Export-ModuleMember -Function *-TargetResource

