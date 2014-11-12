Configuration PermEventDemo4 {
    Import-DscResource -Module WMIPermanentEvents
    Node Localhost {
        WMIEventFilter ProcessEventFilter {
            Name = 'ProcessEventFilter'
            Query = "SELECT * FROM __InstanceCreationEvent WITHIN 5 WHERE TargetInstance ISA 'Win32_Process'"
            Ensure = 'Present'
        }

        WMICommandLineConsumer CommandLineConsumer {
            Name = 'ProcessCommandLine'
            ExecutablePath = 'cmd.exe'
            CommandLineTemplate = '/C C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe -Command { Add-Content %TargetInstance.Name% -Path C:\Dell\testprocess.log }'
            Ensure = 'Present'
        }

        WMIEventBinding ProcessCommandLineBinder {
            Filter = 'ProcessEventFilter'
            Consumer = 'ProcessCommandLine'
            ConsumerType = 'CommandLine'
            DependsOn = '[WMIEventFilter]ProcessEventFilter','[WMICommandLineConsumer]CommandLineConsumer'
            Ensure = 'Present'
        }
    }
}

PermEventDemo4

