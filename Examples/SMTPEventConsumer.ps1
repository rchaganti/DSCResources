Configuration PermEventDemo3 {
    Import-DscResource -Module WMIPermanentEvents
    Node Localhost {
        WMIEventFilter ProcessEventFilter {
            Name = 'ProcessEventFilter'
            Query = "SELECT * FROM __InstanceCreationEvent WITHIN 5 WHERE TargetInstance ISA 'Win32_Process'"
            Ensure = 'Absent'
        }

        WMISMTPConsumer ProcessSMTPConsumer {
            Name = 'ProcessSMTP'
            Message = 'New Process Created with name %TargetInstance.Name%'
            Subject = 'new Process Created'
            SMTPServer = 'smtp.google.com'
            ToLine = 'Ravikanth@Ravichaganti.com'
            FromLine = 'Ravikanth_Chaganti@Dell.com'
            Ensure = 'Absent'
        }

        WMIEventBinding ProcessEventLogBinder {
            Filter = 'ProcessEventFilter'
            Consumer = 'ProcessSMTP'
            Ensure = 'Absent'
            ConsumerType = 'SMTP'
            DependsOn = '[WMIEventFilter]ProcessEventFilter','[WMISMTPConsumer]ProcessSMTPConsumer'
        }
    }
}

PermEventDemo3