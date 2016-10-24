function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("yes")]
        [System.String]
        $IsSingleInstance,

        [parameter(Mandatory = $true)]
        [System.String]
        $Path
    )
    
    $configuration = @{
        IsSingleInstance = 'Yes'
        Path = $Path
    }

    Write-Verbose 'Checking if VS Code Insiders is installed ...'
    if (Get-VSCodeInstall)
    {
        $configuration.Add('Ensure','Present')
    }
    else
    {
        $configuration.Add('Ensure','Absent')
    }

    $configuration
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("yes")]
        [System.String]
        $IsSingleInstance,

        [parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter()]
        [System.String]
        [ValidateSet('Present','Absent')]
        $Ensure = 'Present'
    )
    
    if ($Ensure -eq 'Present')
    {
        Write-Verbose 'Installing VS Code Insiders ...'
        $loadInf = '@
[Setup]
Lang=english
Dir=C:\Program Files (x86)\Microsoft VS Code Insiders
Group=Visual Studio Code
NoIcons=0
Tasks=desktopicon,addcontextmenufiles,addcontextmenufolders,addtopath
        @'

        $infPath = "${env:TEMP}\load.inf"
        $loadInf | Out-File $infPath
        try
        {
            Start-Process -FilePath $Path -ArgumentList "/VERYSILENT /LOADINF=${infPath}" -Wait
        }
        catch
        {
            Write-Error $_
        }
        
        Write-Verbose -Message 'Testing if VS Code Insiders is installed or not ..'
        if (Get-VSCodeInstall)
        {
            Write-Verbose -Message 'VS Code Insiders install successful ...'
        }
        else
        {
            Write-Error -Message 'VS Code Insiders install failed ...'
        }
    }
    else 
    {
        Write-Verbose 'Uninstalling VS Code Insiders ...'
        $vsCodeInstall = Get-VSCodeInstall
        try
        {
            Start-Process -FilePath $($vsCodeInstall.UninstallString) -ArgumentList '/VERYSILENT' -Wait
            Start-Sleep -Seconds 10
        }
        catch
        {
            Write-Error $_
        }
        
        Write-Verbose -Message 'Testing if VS Code Insiders is uninstalled or not ..'
        if (Get-VSCodeInstall)
        {
            Write-Error -Message 'VS Code Insiders uninstall failed ...'
        }
        else
        {
            Write-Verbose -Message 'VS Code Insiders uninstall successful ...'
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
        [ValidateSet("yes")]
        [System.String]
        $IsSingleInstance,

        [parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter()]
        [System.String]
        [ValidateSet('Present','Absent')]
        $Ensure = 'Present'
    )

    Write-Verbose -Message 'Testing if VS Code Insiders is installed ...'
    if (Get-VSCodeInstall)
    {
        if ($Ensure -eq 'Present')
        {
            Write-Verbose -Message 'VS Code Insiders is already installed. No action needed.'
            return $true
        }
        else
        {
            Write-Verbose -Message 'VS Code insiders is installed while it should not. It will be removed.'
            return $false
        }
    }
    else
    {
        if ($Ensure -eq 'Present')
        {
            Write-Verbose -Message 'VS Code Insiders is not installed. It will be installed.'
            return $false
        }
        else
        {
            Write-Verbose -Message 'VS Code Insiders is not installed. No action needed.'
            return $true
        }
    }
}

Function Get-VSCodeInstall
{
    switch ($env:PROCESSOR_ARCHITECTURE)
    {
        'AMD64' { $UninstallKey = 'HKLM:\\SOFTWARE\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\*' }
        'x86' { $UninstallKey = 'HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\*' }
    }

    $products = Get-ItemProperty -Path $UninstallKey | Select DisplayName, DisplayVersion, InstallLocation, UninstallString
    if ($products.DisplayName -contains 'Microsoft Visual Studio Code Insiders')
    {
        return $products.Where({$_.DisplayName -eq 'Microsoft Visual Studio Code Insiders'})
    }
}

Export-ModuleMember -Function *-TargetResource

