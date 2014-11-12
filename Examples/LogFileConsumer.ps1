Configuration PermEventDemo1 {
    Import-DscResource -Module WMIPermanentEvents
    Node Localhost {
        WMIEventFilter ProcessFilter {
            Name = 'ProcessFilter'
            Query = "SELECT * FROM __InstanceCreationEvent WITHIN 5 WHERE TargetInstance ISA 'Win32_Process'"
            Ensure = 'Present'
        }

        WMILogFileConsumer LogFileConsumer {
            Name = 'ProcessLog'
            Filename = 'C:\Dell\Process.log'
            Text = 'New Process Created: %TargetInstance.Name%'
            Ensure = 'Present'
        }

        WMIEventBinding ProcessLogBinder {
            Filter = 'ProcessFilter'
            Consumer = 'ProcessLog'
            ConsumerType = 'LogFile'
            Ensure = 'Present'
            DependsOn = '[WMIEventFilter]ProcessFilter','[WMILogFileConsumer]LogFileConsumer'
        }
    }
}

PermEventDemo1