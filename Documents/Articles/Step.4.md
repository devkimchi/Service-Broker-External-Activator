# Service Broker External Activator for SQL Server Step by Step #4 #

From the previous post, [Step 3: External Activator Application Development](http://devkimchi.com/891/service-broker-external-activator-for-sql-server-step-by-step-3/), we have developed a console application activated by  Service Broker (SB) External Activator (EA). In this article, we are going to configure the EA Windows Service that we have [previously installed](http://devkimchi.com/811/service-broker-external-activator-for-sql-server-step-by-step-1/).

Its sample source codes can be found at: [devkimchi/Service-Broker-External-Activator](https://github.com/devkimchi/Service-Broker-External-Activator)

> * [Step 1: Service Broker External Activator Service Setup](http://devkimchi.com/811/service-broker-external-activator-for-sql-server-step-by-step-1/)
> * [Step 2: SQL Server Setup](http://devkimchi.com/831/service-broker-external-activator-for-sql-server-step-by-step-2/)
> * [Step 3: External Activator Application Development](http://devkimchi.com/891/service-broker-external-activator-for-sql-server-step-by-step-3/)
> * **Step 4: External Activator Service Configuration**
> * [Step 5: Putting Them Altogether](http://devkimchi.com/1051/service-broker-external-activator-for-sql-server-step-by-step-5/)


## External Activator Service Configuration ##

We have installed EA Windows Service, created SB objects including message types, contracts, queues, services and event notifications, developed a console application to process messages passed from SQL Server via SB. In order to start the Windows Service, we need to configure basic settings before starting it. The configuration file can be found `C:\Program Files\Service Broker\External Activator\Config\EAService.config`, if it has been installed with default options.


### NotificationServiceList ###

<pre lang="xml">
<NotificationServiceList>
    <NotificationService name="TrackingNotificationService" id="100" enabled="true">
        <Description>Tracking Notification Service</Description>
        <ConnectionString>
            <Unencrypted>server=DEVKIMCHI;database=SourceDB;Application Name=SBEASampleApp;Integrated Security=true;</Unencrypted>
        </ConnectionString>
    </NotificationService>
</NotificationServiceList>
</pre>

* `NotificationService.name`: This is the external notification service name defined in the [Step 2](http://devkimchi.com/831/service-broker-external-activator-for-sql-server-step-by-step-2/#event-notification).
* `ConnectionString.Unencrypted`: This is the database connection string.
  * Make sure that the server **MUST** be a computer name. In other words, domain name like `localhost` or `sqlsvr.contoso` won't work.
  * Even though, it looks like a normal database connection string, providing username and password, instead of Windows Account, will result in database connection failure. That is, `Integrated Security=true` **MUST** be present.


### ApplicationServiceList ###

<pre lang="xml">
<ApplicationServiceList>
    <ApplicationService name="SBEASampleApp" enabled="true">
        <OnNotification>
            <ServerName>DEVKIMCHI</ServerName>
            <DatabaseName>SourceDB</DatabaseName>
            <SchemaName>dbo</SchemaName>
            <QueueName>TrackingRequestQueue</QueueName>
        </OnNotification>
        <LaunchInfo>
            <ImagePath>C:\Temp\SBEASampleApp\SBEASampleApp.exe</ImagePath>
            <CmdLineArgs></CmdLineArgs>
            <WorkDir>C:\Temp\SBEASampleApp</WorkDir>
        </LaunchInfo>
        <Concurrency min="1" max="4" />
    </ApplicationService>
</ApplicationServiceList>
</pre>

* `ApplicationService.name`: This is the console application name identified by SQL Server.
* `OnNotification.ServerName`: Again, this is the machine name of SQL Server, not the domain name.
* `OnNotification.DatabaseName`: This is the database where SB is enabled to send event notification.
* `OnNotification.SchemaName`: This is the schema name that defines SB objects. Usually it is `dbo`.
* `OnNotification.QueueName`: This is the queue name defined in the [Step 2](http://devkimchi.com/831/service-broker-external-activator-for-sql-server-step-by-step-2/#event-notification).
* `LaunchInfo.ImagePath`: This is the full file path of the console application.
* `LaunchInfo.CmdLineArgs`: This will be passed into the console application for processing.
* `LaunchInfo.WorkDir`: This is the full directory path of the console application.
* `Concurrency.max`: Maximum number of the process to be run at the same time. Usually this value is equivalent to the number of CPU cores of the machine.


### LogSettings ###

<pre lang="xml">
<LogSettings>
    <LogFilter>
        <TraceFlag>All Levels</TraceFlag>
        <TraceFlag>All Modules</TraceFlag>
        <TraceFlag>All Entities</TraceFlag>
        <TraceFlag>Verbose</TraceFlag>
    </LogFilter>
</LogSettings>
</pre>

If you see the [schema definition of EA](http://schemas.microsoft.com/sqlserver/2008/10/servicebroker/externalactivator/EAServiceConfig.xsd), the details of log filter can be easily understood. Make sure that, the settings above should be modified for production use.


---
We have so far configured EA Windows Service to run. In the next article, as a final step, [Step 5: Putting Them Altogether](http://devkimchi.com/1051/service-broker-external-activator-for-sql-server-step-by-step-5/), we will put everything together, run the Service, and run some sample `INSERT`, `UPDATE`, and `DELETE`.

