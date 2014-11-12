Configuration PermEventDemo5 {
    Import-DscResource -Module WMIPermanentEvents
    Node Localhost {
        WMIEventFilter ProcessEventFilter {
            Name = 'ProcessEventFilter'
            Query = "SELECT * FROM __InstanceCreationEvent WITHIN 5 WHERE TargetInstance ISA 'Win32_Process'"
            Ensure = 'Present'
        }

        WMIActiveScriptConsumer ProcessScriptConsumer {
            Name = 'ProcessScript'
            ScriptFileName = 'C:\Dell\Test.vbs'
            Ensure = 'Present'
        }

        WMIEventBinding ProcessScriptBinder {
            Filter = 'ProcessEventFilter'
            Consumer = 'ProcessScript'
            ConsumerType = 'Script'
            DependsOn = '[WMIEventFilter]ProcessEventFilter','[WMIActiveScriptConsumer]ProcessScriptBinder'
            Ensure = 'Present'
        }
    }
}

PermEventDemo5