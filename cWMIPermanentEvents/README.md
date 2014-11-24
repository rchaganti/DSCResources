# DSCResources #
### Custom DSC resource modules for managing WMI Permanent Event Subscriptions by [PowerShell Magazine](http://www.powershellmagazine.com "PowerShell Magazine"). ###

----------

[From MSDN article](http://msdn.microsoft.com/en-us/library/aa393014%28v=vs.85%29.aspx):
You may want to write an application that can react to events at any time. For example, an administrator may want to receive an email message when specific performance measures decline on network servers. In this case, your application should run at all times. However, running an application continuously is not an efficient use of system resources. Instead, WMI allows you to create a permanent event consumer.

A permanent event consumer receives events until its registration is explicitly canceled. Creating WMI event consumers requires good amount of WMI knowledge and could be complex for beginners. This DSC resource module helps simplify using WMI permanent events.

The WMI Permanent Events DSC resource module contains the following DSC resources.
- [cWMIEventFilter](https://github.com/rchaganti/DSCResources/tree/master/cWMIPermanentEvents/DSCResources/cWMIEventFilter) is used to create event filter instances for a given event query and event namespace. 
- [cWMIEventBinding](https://github.com/rchaganti/DSCResources/tree/master/cWMIPermanentEvents/DSCResources/cWMIEventBinding) is used to create binding between an event filter instance and an event consumer instance.
- [cWMIEventLogConsumer](https://github.com/rchaganti/DSCResources/tree/master/cWMIPermanentEvents/DSCResources/cWMIEventLogConsumer) is used to create an instance of WMI Event Log consumer that writes to application log in response to an event.
- [cWMILogFileConsumer](https://github.com/rchaganti/DSCResources/tree/master/cWMIPermanentEvents/DSCResources/cWMILogFileConsumer) is used to create an instance of WMI Log File that writes to a text log file in response to an event.
- [cWMIActiveScriptConsumer](https://github.com/rchaganti/DSCResources/tree/master/cWMIPermanentEvents/DSCResources/cWMIActiveScriptConsumer) is used to create an instance of WMI Active Script Consumer that executes a specified VBScript file and VBScript text fragment in response to an event.
- [cWMICommandLineConsumer](https://github.com/rchaganti/DSCResources/tree/master/cWMIPermanentEvents/DSCResources/cWMICommandLineConsumer) is used to create an instance of WMI CommandLine Consumer that executes a native application or a batch script in response to an event.
- [cWMISMTPConsumer](https://github.com/rchaganti/DSCResources/tree/master/cWMIPermanentEvents/DSCResources/cWMISMTPConsumer) is used to create an instance of WMI SMTP Consumer that sends an email in response to an event.

For meaningful use of these resources, you must always create a filter instance, a consumer instance (out of the five standard consumers) and then binding these two together using a event binding resource.

Note that you must use the Import-DscResource cmdlet to import the custom DSC resource module before any of the above resources can be used in the configuration script.

    Import-DscResource -Module cWMIPermanentEvents

The Name property of cWMIEventFilter, cWMICommandLineConsumer, cWMIActiveScriptConsumer, cWMILogFileConsumer, cWMIEventLogConsumer, and cWMISMTPConsumer resources identifies the WMI instance created by the DSC resource. This must be a unique value and cannot be re-used within the same type of instance. For example, no two event filter instances can have the same name and so on.
 
The following examples illustrate how each of these resources are used.

###Using cWMIEventFilter resource####
[Event filter](http://msdn.microsoft.com/en-us/library/aa394639(v=vs.85).aspx) is the first step in creating a permanent WMI event subscription.

![](http://i.imgur.com/y3bLtvb.png) 

As shown above, the *Name* and *Query* properties are mandatory. The *EventNamespace* is, by default, set to *root\cimv2*. This can be changed. The cWMIEventFilter DSC resource always creates the event filter instance in the *root\subscription* namespace. This is not same as the value you provide as *EventNamespace*.

    cWMIEventFilter UFDDetection {
       Name = 'UFDFilter'
       Query = "SELECT * FROM __InstanceCreationEvent WITHIN 2 WHERE
                               TargetInstance ISA 'Win32_Volume' AND
                               TargetInstance.Label='Backup' AND
                               TargetInstance.DriveType=2"
       EventNamespace = 'root\cimv2'
       Ensure = 'Present'
    }

In the above example, we are creating an event filter instance for any detecting any removable device insertion. Once the event filter instance is created, we need to decide upon what type of event consumer needs to be used as a response to an event.

> An event filter can be associated with any number of event consumers.

###Using cWMICommandLineConsumer resource####
The [WMI commandline event consumer](http://msdn.microsoft.com/en-us/library/aa389231%28v=vs.85%29.aspx) helps in executing a native application or a command batch script in response to an event. This WMI class has many properties that are generally not used. Therefore, the DSC resource associated with this consumer has only a minimal set of required properties.

![](http://i.imgur.com/CQCSRH9.png)

The *CommandLineTemplate* property is used to specify the commandline arguments for an executable. The [WMI standard string template](http://msdn.microsoft.com/en-us/library/aa393954%28v=vs.85%29.aspx) can be used as a part of the value provided.

If the path to the executable is specified as a part of the *CommandLineTemplate*, then there is no need to use the *ExecutablePath* property.

    cWMICommandLineConsumer UFDCommandLine {
       Name = 'UFDCommandLineConsumer'
       CommandLineTemplate = 'cmd.exe /c C:\Scripts\Backup.cmd %TargetInstance.DriveLetter%'
       Ensure = 'Present'
    }
 
As you see in the above example, the *CommandLineTemplate* uses the name of the executable and the standard string template for passing the drive letter of the removable drive to the batch script. Here is an example of the batch file that leverages the commandline arguments sent from the event consumer.

    @ECHO OFF
    FOR /f %%a in ('WMIC OS GET LocalDateTime ^| find "."') DO set DTS=%%a
    set TODAY=%DTS:~0,4%-%DTS:~4,2%-%DTS:~6,2%
    Set BackupFolder=%1\%TODAY%
    mkdir %BackupFolder%
    xcopy /E /Y C:\DSCDemo\*.* %BackupFolder%

####Using cWMIEventLogConsumer resource####
The WMI NT Event Log consumer can be used to write event log entries to the application log. As with other consumers, this consumer too supports usage of WMI standard string templates.
![](http://i.imgur.com/9fJm1IF.png)

As shown above, only the *EventID* and Name properties are mandatory. The *Category* property is set to 0, by default and the *EventType* is set to *Information*. However, an event log message has no meaning if the even body does not contain any useful information. This is where the *InsertionStringTemplates* property is used. This property takes an array of strings and the number of strings you can specify are controlled by the *NumberOfInsertionStrings* property which, by default, is set to 1. Here is an example that shows how the DSC resource is used.

    cWMIEventLogConsumer UFDEventLog {
       Name = 'UFDEventLog'
       EventID = 10011
       Category = 0
       EventType = 'information'
       SourceName = 'WMI'
       InsertionStringTemplates = 'A new UFD drive with volume name Backup is found with a drive letter %TargetInstance.DriveLetter%'
       Ensure = 'Present'
    }

Observe how we used the WMI standard string template in the value provided for *InsertionStringTemplates* property. This method can be used across all standard consumers.

####Using cWMILogFileConsumer resource####
The [WMI Log File consumer](http://msdn.microsoft.com/en-us/library/aa392277(v=vs.85).aspx) can be used to write entries in to a text log file in response to an event.

![](http://i.imgur.com/i8ExDVQ.png)

When using this resource, you must provide the Name, Text, and the *Filename* properties. The value you provide to the *Filename* property must be an absolute path and not a relative one. The *Text* property takes the WMI standard string template.

    cWMILogFileConsumer LogFileConsumer {
       Name = 'UFDLogFile'
       Filename = 'C:\Logs\Backup.log'
       Text = 'Removable drive with volume name backup is found with drive letter %TargetInstance.DriveLetter%. Backup will be initiated.'
       Ensure = 'Present'
    }

The *MaximumFileSize* can be used to auto-rotate the log file after a certain size. This is, by default, set to 65KB.

####Using cWMISMTPConsumer resource####
The [WMI SMTP consumer](http://msdn.microsoft.com/en-us/library/aa393629(v=vs.85).aspx) can be used to send an email in response to an event.

![](http://i.imgur.com/gtOkU2T.png) 

This consumer class does not support authenticating to the SMTP Server provided as a value for the *SMTPServer* property. Therefore, you cannot use most popular SMTP Servers such as Gmail and so on. 

Along with Name and *SMTPServer* properties, the *FromLine* and *ToLine* properties are also mandatory. The *Message* property can be used to specify the body of the email while the *Subject* property is self-explained. Both these properties support WMI standard string templates.

    cWMISMTPConsumer UFDSMTP {
       Name = 'UFDSMTP'
       Message = 'UFD drive with volume name Backup is attached with a drive letter %TargetInstance.DriveLetter%.'
       Subject = 'UFD Detection'
       SMTPServer = 'smtp1.mymailserver.com'
       ToLine = 'ToUser@SomeDomain.com'
       FromLine = 'FromUser@AnotherDomain.com'
       Ensure = 'Present'
    }
####Using cWMIActiveScriptConsumer resource####
The WMI Active Script consumer can be used to execute a VBScript file or a VBScript text fragment in response to an event.

![](http://i.imgur.com/vNC8QXF.png)

While the *Name* property is only shown as mandatory, it is important that you specify either *ScriptFileName* or *ScriptText* to be executed in response to an event. Note that these properties are mutually exclusive.

You can use WMI standard string templates both in the target script file or in the script text. The scripting engine is always *VBScript*. No other scripting engines are supported.

    cWMIActiveScriptConsumer UFDScript {
       Name = 'UFDScript'
       ScriptText = '
      Set objFSO=CreateObject("Scripting.FileSystemObject")
      curDate = Year(Date) & "-" & Month(Date) & "-" & Day(Date)
      objFolder = TargetEvent.TargetInstance.DriveLetter & "\" & curDate
      Set bkFolder = objFSO.CreateFolder(objFolder)
      objFSO.CopyFolder "c:\Scripts", objFolder
      objFile.Close
    '
    Ensure = 'Present'
    }

As you see in the above example, I have used ScriptText property and inserted the WMI standard string template to pass the drive letter of the newly attached removable drive to the script.

####Using cWMIEventBinding resource####
The final step after creating an event filter and a chosen event consumer instances is to bind them together. This is where the cWMIEventBinding resource helps.

![](http://i.imgur.com/hGrQKIP.png)

Since this resource takes the *Filter* and *Consumer* names as the required values, I have made *ConsumerType* also a mandatory property. Using this makes it easy to create WMI instances for the specific objects. The rest of the properties are a mapping from the WMI class and I DO NOT recommend changing the default values.

    cWMIEventBinding UFDCommandLineBinding {
       Filter = 'UFDFilter'
       Consumer = 'UFDCommandLineConsumer'
       ConsumerType = 'CommandLine'
       DependsOn = '[WMIEventFilter]UFDDetection','[WMICommandLineConsumer]UFDCommandLineConsumer'
       Ensure = 'Present'
    }

The *DependsOn* property of the DSC resource is used to ensure that the event filter and consumer instances are created before trying to bind them together.