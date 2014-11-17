Configuration PermEventDemo3 {
    Import-DscResource -Module PSMag
    Node Localhost {
        WMIEventFilter ProcessEventFilter {
            Name = 'ProcessEventFilter'
            Query = "SELECT * FROM __InstanceCreationEvent WITHIN 5 WHERE TargetInstance ISA 'Win32_Process'"
            Ensure = 'Present'
        }

        WMISMTPConsumer ProcessSMTPConsumer {
            Name = 'ProcessSMTP'
            Message = 'New Process Created with name %TargetInstance.Name%'
            Subject = 'new Process Created'
            SMTPServer = 'smtp.google.com'
            ToLine = 'ToUser@SomeDomain.com'
            FromLine = 'FromUser@AnotherDomain.com'
            Ensure = 'Present'
        }

        WMIEventBinding ProcessEventLogBinder {
            Filter = 'ProcessEventFilter'
            Consumer = 'ProcessSMTP'
            Ensure = 'Present'
            ConsumerType = 'SMTP'
            DependsOn = '[WMIEventFilter]ProcessEventFilter','[WMISMTPConsumer]ProcessSMTPConsumer'
        }
    }
}

PermEventDemo3