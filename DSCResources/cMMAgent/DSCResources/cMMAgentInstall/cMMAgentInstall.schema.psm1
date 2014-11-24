Configuration cMMAgentInstall {
    Param (
        [Parameter(Mandatory)]
        [String]$Path,

        [Parameter(Mandatory)]
        [String]$WorkspaceID,

        [Parameter(Mandatory)]
        [String]$WorkspaceKey,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]$Ensure = 'Present'
    )
    
    $CommandLineArguments = '/Q /C:"setup.exe /qn ADD_OPINSIGHTS_WORKSPACE=1 AcceptEndUserLicenseAgreement=1 '
    $CommandLineArguments += "OPINSIGHTS_WORKSPACE_ID=$WorkspaceID "
    $CommandLineArguments += "OPINSIGHTS_WORKSPACE_KEY=$WorkspaceKey`""

    Package MMAgentSetup {
        Name = 'Microsoft Monitoring Agent'
        ProductId = 'EB03FA06-01A7-49F7-8BD0-0AB92D905899'
        Path = $Path
        Arguments = $CommandLineArguments
        Ensure = $Ensure
    }
}