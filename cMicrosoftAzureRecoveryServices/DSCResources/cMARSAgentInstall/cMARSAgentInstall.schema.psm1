Configuration cMARSAgentInstall {
    Param (
        [Parameter(Mandatory)]
        [String] $SetupPath,

        [Parameter()]
        [Bool] $EnableWindowsUpdate = $false,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String] $Ensure = 'Present'
    )
    
    if ($Ensure -eq 'Absent') {
        $CommandLineArguments = '/q /d'
        Package AzureBackupSetup {
            Name = 'Microsoft Azure Recovery Services Agent'
            ProductId = 'FFE6D16C-3F87-4192-AF94-DDBEFF165106'
            Path = $SetupPath
            Arguments = $CommandLineArguments
            Ensure = 'Absent'
        }
    } else {
        $CommandLineArguments = "/q "
        if ($EnableWindowsUpdate) {
            $CommandLineArguments += '/m'
        } else {
            $CommandLineArguments += '/nu'
        }

        Package AzureBackupSetup {
            Name = 'Microsoft Azure Recovery Services Agent'
            ProductId = 'FFE6D16C-3F87-4192-AF94-DDBEFF165106'
            Path = $SetupPath
            Arguments = $CommandLineArguments
            Ensure = 'Present'
        }
    }
}