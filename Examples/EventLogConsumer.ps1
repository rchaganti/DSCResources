Configuration PermEventDemo2 {
    Import-DscResource -Module WMIPermanentEvents
    Node Localhost {
        WMIEventFilter ProcessEventFilter {
            Name = 'ProcessEventFilter'
            Query = "SELECT * FROM __InstanceCreationEvent WITHIN 5 WHERE TargetInstance ISA 'Win32_Process'"
            Ensure = 'Present'
        }

        WMIEventLogConsumer ProcessEventLog {
            Name = 'ProcessEventLog'
            EventID = 10011
            Category = 0
            EventType = 'Error'
            SourceName = 'WSH'
            InsertionStringTemplates = 'New Process Created: %TargetInstance.Name%'
            Ensure = 'Present'
        }

        WMIEventBinding ProcessEventLogBinder {
            Filter = 'ProcessEventFilter'
            Consumer = 'ProcessEventLog'
            Ensure = 'Present'
            ConsumerType = 'EventLog'
            DependsOn = '[WMIEventFilter]ProcessEventFilter','[WMIEventLogConsumer]ProcessEventLog'
        }
    }
}

PermEventDemo2