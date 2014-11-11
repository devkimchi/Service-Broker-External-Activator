# Service Broker External Activator for SQL Server Step by Step #2 #

From the previous post, [Step 1: Service Broker External Activator Service Setup](http://devkimchi.com/811/service-broker-external-activator-for-sql-server-step-by-step-1/), we have installed a Windows Service application for Service Broker External Activator (EA). In this article, we are going to setup SQL Server to enable Service Broker (SB).

Its sample source codes can be found at: [devkimchi/Service-Broker-External-Activator](https://github.com/devkimchi/Service-Broker-External-Activator)

> * [Step 1: Service Broker External Activator Service Setup](http://devkimchi.com/811/service-broker-external-activator-for-sql-server-step-by-step-1/)
> * **Step 2: SQL Server Setup**
> * [Step 3: External Activator Application Development](http://devkimchi.com/891/service-broker-external-activator-for-sql-server-step-by-step-3/)
> * [Step 4: External Activator Service Configuration](http://devkimchi.com/951/service-broker-external-activator-for-sql-server-step-by-step-4/)
> * [Step 5: Putting Them Altogether](http://devkimchi.com/1051/service-broker-external-activator-for-sql-server-step-by-step-5/)


## SQL Server Setup for Service Broker ##

> **Business Requirements**:
> 
> We are about to trace product details changes. As soon as a product is added, updated, or deleted, those change details should be logged in a separated database and table so that the log table can be utilised for other purpose.

Firstly, we need to create two databases &ndash; `SourceDB` for source that contains product details and `TrackingDB` for tracking that stored log details.


### Creating Databases ###

```sql
USE [master]
GO

CREATE DATABASE [SourceDB]
GO

CREATE DATABASE [TrackingDB]
GO
```

### Creating Tables ###

Once both databases are created, each database needs a table respectively &ndash; `Products` on `SourceDB` and `TrackingLogs` on `TrackingDB`.

```sql
USE [SourceDB]
GO

CREATE TABLE [dbo].[Products] (
    [ProductId]     [int]           IDENTITY(1,1)   NOT NULL,
    [Name]          [nvarchar](50)                  NOT NULL,
    [Description]   [nvarchar](50)                  NULL,
    [Price]         [decimal](18, 2)                NOT NULL,
    CONSTRAINT [PK_Products] PRIMARY KEY CLUSTERED (
        [ProductId] ASC
    ) WITH (
        PAD_INDEX = OFF,
        STATISTICS_NORECOMPUTE = OFF,
        IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON,
        ALLOW_PAGE_LOCKS = ON
    ) ON [PRIMARY]
) ON [PRIMARY]
GO

USE [TrackingDB]
GO

CREATE TABLE [dbo].[TrackingLogs] (
    [TrackingLogId] [int]           IDENTITY(1,1)   NOT NULL,
    [Source]        [nvarchar](50)                  NOT NULL,
    [Field]         [nvarchar](50)                  NOT NULL,
    [TrackingType]  [nvarchar](8)                   NOT NULL,
    [OldValue]      [nvarchar](MAX)                 NULL,
    [NewValue]      [nvarchar](MAX)                 NULL,
    CONSTRAINT [PK_TrackingLogs] PRIMARY KEY CLUSTERED (
        [TrackingLogId] ASC
    ) WITH (
        PAD_INDEX = OFF,
        STATISTICS_NORECOMPUTE = OFF,
        IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON,
        ALLOW_PAGE_LOCKS = ON
    ) ON [PRIMARY]
) ON [PRIMARY]
GO
```

<a name="creating-stored-procedures"></a>
### Creating Stored Procedures ###

We have just created two tables. So far so good. Now, we are going to create stored procedures. They will send messages to EA or receive messages from EA.

```sql
USE [SourceDB]
GO

CREATE PROCEDURE [usp_SendTrackingRequest]
    @productId      AS INT,
    @trackingType   AS NVARCHAR(8),
    @inserted       AS XML,
    @deleted        AS XML
AS
BEGIN

    SET NOCOUNT ON;

    DECLARE @data    AS XML

    SET @data = (SELECT
                    @productId              AS ProductId,
                    @trackingType           AS TrackingType,
                    COALESCE(@inserted, '') AS Inserted,
                    COALESCE(@deleted, '')  AS Deleted
                 FOR XML PATH(''), ROOT('Changes'), ELEMENTS)

    DECLARE @handle    AS UNIQUEIDENTIFIER

    BEGIN DIALOG CONVERSATION @handle  
        FROM
            SERVICE [TrackingInitiatorService]
        TO
            SERVICE 'TrackingTargetService'
        ON
            CONTRACT [TrackingContract]
        WITH
            ENCRYPTION = OFF;

    SEND
        ON CONVERSATION @handle
        MESSAGE TYPE [TrackingRequest] (@data)

END
GO
```

* This stored procedure is called by triggers when `INSERT`, `UPDATE` or `DELETE` action occurs.
* The triggers passes inserted/deleted records to the stored procedure.
* The stored procedure wraps passed values in an XML format.
* Then the stored procedure puts the XML value into a message and send it to SB.

There are two key parts in this stored procedure:

* Both inserted and deleted values are formatted as an XML type as SB basically consumes SOAP message format.
* A conversation is opened to send the XML message to an external application through SB and EA.

Make sure that the stored procedure only starts conversation and send the message through the conversation. The external application receives the message and processes it and closes the conversation.


### Creating Servie Broker Objects ###

This is the most important part of this post to setup Service Broker. Consuming SB requires many different entities such as `Message Type`, `Contract`, `Queue`, `Service` and `Event Notification`. Now, we are creating those objects in this order &ndash; `Message Type`, `Contract`, `Queue`, `Service` and `Event Notification` as they are all dependent on another.


#### Enable Service Broker ####

As `SourceDB` is the one to track changes, we need to enable SB on this database. Make sure that this uses `ALTER DATABASE` statement, which means that all transactions must be completed before executing the `ALTER` statement. However, for some databases, this might not be possible. In this case, like below, put additional clause, `WITH ROLLBACK IMMEDIATE`. By doing this, any transaction at the instance of running `ALTER DATABASE` statement will be rolled back.

```sql 
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'SourceDB' AND is_broker_enabled = 0)
BEGIN
    ALTER DATABASE [SourceDB] SET NEW_BROKER WITH ROLLBACK IMMEDIATE
END
GO
```


#### `Mesage Type` ####

We have two message types &ndash; request and response. They define how messages are formed.

```sql
CREATE MESSAGE TYPE [TrackingRequest]
    VALIDATION = WELL_FORMED_XML
GO

CREATE MESSAGE TYPE [TrackingResponse]
    VALIDATION = NONE    
GO
```


#### `Contract` ####

Both message types are bunched in a contract.

```sql
CREATE CONTRACT [TrackingContract] (
    [TrackingRequest]   SENT BY INITIATOR, 
    [TrackingResponse]  SENT BY TARGET
    )
GO
```

Even though, this is not the exact simile, it is easy to understand that `INITIATOR` is a message sender and `TARGET` is a message receiver.


<a name="queue"></a>
#### `Queue` ####

Messages are stored in queues before being consumed by services.

```sql
CREATE QUEUE [TrackingRequestQueue]
    WITH
        STATUS = ON,
        RETENTION = OFF
    ON [PRIMARY]
GO

CREATE QUEUE [TrackingResponseQueue]
    WITH 
        STATUS = ON,
        RETENTION = OFF
    ON [PRIMARY]
GO

CREATE QUEUE [TrackingNotificationQueue]
    WITH
        STATUS = ON,
        RETENTION = OFF 
    ON [PRIMARY]
GO
```

Each queue takes responsibility for each message types. Wait. There is another queue, `TrackingNotificationQueue` , doesn't belong to either request nor response. This queue will be consumed by EA, which will be explained later on.


<a name="service"></a>
#### `Service` ####

Services manage queues which a contract combines.

```sql
CREATE SERVICE [TrackingInitiatorService]
    ON QUEUE [TrackingResponseQueue] ([TrackingContract])
GO

CREATE SERVICE [TrackingTargetService]
    ON QUEUE [TrackingRequestQueue] ([TrackingContract])
GO

CREATE SERVICE [TrackingNotificationService]
    ON QUEUE [TrackingNotificationQueue] ([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification])
GO
```

There are three distinctive services. One for INITIATOR (sender) and another for TARGET (receiver) and the other for EA. Please bear in mind that sender looks after the **RESPONSE** queue and receiver takes care of the **REQUEST** queue. Both request service and response service are bundled by a contract, while `TrackingNotificationService` uses default event notification contract.


<a name="event-notification"></a>
#### `Event Notification` ####

We have created all necessary message types, contracts, queues and services. Now, we need to create an event notification to throw messages to EA.

```sql
CREATE EVENT NOTIFICATION [TrackingEventNotification]
    ON QUEUE [TrackingRequestQueue]
    FOR QUEUE_ACTIVATION
    TO SERVICE 'TrackingNotificationService', 'current database'
GO
```

This raises an event as soon as a message is loaded on the queue, `TrackingRequestQueue`, and activated. At the same time, the event lets the service, `TrackingNotificationService`, know the EA starts processing the message. When the EA application receives this event notification, it looks for `TrackingRequestQueue` if there is a message contracted as `TrackingRequest` or not.

Let's go back to the stored procedure we created above. The stored procedure sends a message, `TrackingRequest`, which is stored in `TrackingRequestQueue`. This queue is consumed by `TrackingTargetService`. As stated above, the `TrackingTargetService` is a receiver, so a conversation is opened within the stored procedure, then the receiver sends a signal to EA to process the message.


### Creating Triggers ###

We've created databases, tables, stored procedures and SB objects. Now, we are creating triggers to get what the changes are.

```sql
CREATE TRIGGER [dbo].[trg_INS_Products]
    ON [dbo].[Products]
    AFTER INSERT
AS
BEGIN

    SET NOCOUNT ON

    DECLARE @productId      AS INT
    DECLARE @trackingType   AS NVARCHAR(8)
    DECLARE @inserted       AS XML
    DECLARE @deleted        AS XML

    SELECT  @productId      = ProductId FROM inserted
    SET     @trackingType   = 'INSERT'
    SET     @inserted       = (SELECT * FROM inserted FOR XML PATH(''), ROOT('Row'), ELEMENTS)
    SET     @deleted        = NULL

    EXECUTE [dbo].[usp_SendTrackingRequest] @productId, @trackingType, @inserted, @deleted

END
GO

CREATE TRIGGER [dbo].[trg_UPD_Products]
    ON [dbo].[Products]
    AFTER UPDATE
AS
BEGIN

    SET NOCOUNT ON

    DECLARE @productId      AS INT
    DECLARE @trackingType   AS NVARCHAR(8)
    DECLARE @inserted       AS XML
    DECLARE @deleted        AS XML

    SELECT  @productId      = ProductId FROM inserted
    SET     @trackingType   = 'UPDATE'
    SET     @inserted       = (SELECT * FROM inserted FOR XML PATH(''), ROOT('Row'), ELEMENTS)
    SET     @deleted        = (SELECT * FROM deleted FOR XML PATH(''), ROOT('Row'), ELEMENTS)

    EXECUTE [dbo].[usp_SendTrackingRequest] @productId, @trackingType, @inserted, @deleted

END
GO

CREATE TRIGGER [dbo].[trg_DEL_Products]
    ON [dbo].[Products]
    AFTER DELETE
AS
BEGIN

    SET NOCOUNT ON

    DECLARE @productId      AS INT
    DECLARE @trackingType   AS NVARCHAR(8)
    DECLARE @inserted       AS XML
    DECLARE @deleted        AS XML

    SELECT  @productId      = ProductId FROM deleted
    SET     @trackingType   = 'DELETE'
    SET     @inserted       = NULL
    SET     @deleted        = (SELECT * FROM deleted FOR XML PATH(''), ROOT('Row'), ELEMENTS)

    EXECUTE [dbo].[usp_SendTrackingRequest] @productId, @trackingType, @inserted, @deleted

END
GO
```

For more readability, triggers for `INSERT`, `UPDATE` and `DELETE` are separated. They do the literally the same job &ndash; To find a record affected, wrap the record as an XML format and send the record to the stored procedure we created above.


### Granting Permissions ###

For Windows 7, Windows Server 2008 or later, you might have heard of the term, **Virtual Account**. This is not a real account but to work as like a service account in Windows 7, Windows Server 2008 or later which is not on Active Directory. As we have already installed Service Broker External Activator Service, we have a virtual account, `NT SERVICE\SSBExternalActivator`. This account has already been assigned to the Windows Service application.

![](http://blob.devkimchi.com/devkimchiwp/2014/11/SSBEAS.Install.03.png)

Permissions need to be granted onto two accounts &ndash; `NT SERVICE\SSBExternalActivator` and `NT AUTHORITY\ANONYMOUS LOGON`. As the former is a virtual account, it actually doesn't exist. Therefore, in order to access to database, it instead uses the latter. Keep this in your mind. Of course, for your production purpose, it would be better to create a service account.

```sql
USE [master]
GO

IF NOT EXISTS (SELECT * FROM sys.syslogins WHERE name = 'NT SERVICE\SSBExternalActivator')
BEGIN
    CREATE LOGIN [NT SERVICE\SSBExternalActivator] FROM WINDOWS
END
GO

USE [TrackingDB]
GO

IF NOT EXISTS (SELECT * FROM sys.sysusers WHERE name = 'NT SERVICE\SSBExternalActivator')
BEGIN
    CREATE USER [NT SERVICE\SSBExternalActivator] FOR LOGIN [NT SERVICE\SSBExternalActivator]
END
GO

ALTER ROLE [db_owner] ADD MEMBER [NT SERVICE\SSBExternalActivator]
GO

USE [SourceDB]
GO

IF NOT EXISTS (SELECT * FROM sys.sysusers WHERE name = 'NT SERVICE\SSBExternalActivator')
BEGIN
    CREATE USER [NT SERVICE\SSBExternalActivator] FOR LOGIN [NT SERVICE\SSBExternalActivator]
END
GO

ALTER ROLE [db_owner] ADD MEMBER [NT SERVICE\SSBExternalActivator]
GO

-- Allows CONNECT to [SourceDB].
GRANT CONNECT
    TO [NT SERVICE\SSBExternalActivator]
GO
 
-- Allows RECEIVE from the queue for the external actvator app.
GRANT RECEIVE
    ON [TrackingNotificationQueue]
    TO [NT SERVICE\SSBExternalActivator]
GO
 
-- Allows VIEW DEFINITION right on the service for the external activator app.
GRANT VIEW DEFINITION
    ON SERVICE::[TrackingNotificationService]
    TO [NT SERVICE\SSBExternalActivator]
GO
 
-- Allows REFRENCES right on the queue schema for the external activator app.
GRANT REFERENCES
    ON SCHEMA::dbo
    TO [NT SERVICE\SSBExternalActivator]
GO

USE [master]
GO

IF NOT EXISTS (SELECT * FROM sys.syslogins WHERE name = 'NT AUTHORITY\ANONYMOUS LOGON')
BEGIN
    CREATE LOGIN [NT AUTHORITY\ANONYMOUS LOGON] FROM WINDOWS
END

USE [TrackingDB]
GO

IF NOT EXISTS (SELECT * FROM sys.sysusers WHERE name = 'NT AUTHORITY\ANONYMOUS LOGON')
BEGIN
    CREATE USER [NT AUTHORITY\ANONYMOUS LOGON] FOR LOGIN [NT AUTHORITY\ANONYMOUS LOGON]
END
GO

ALTER ROLE [db_owner] ADD MEMBER [NT AUTHORITY\ANONYMOUS LOGON]
GO

USE [SourceDB]
GO

IF NOT EXISTS (SELECT * FROM sys.sysusers WHERE name = 'NT AUTHORITY\ANONYMOUS LOGON')
BEGIN
    CREATE USER [NT AUTHORITY\ANONYMOUS LOGON] FOR LOGIN [NT AUTHORITY\ANONYMOUS LOGON]
END
GO

ALTER ROLE [db_owner] ADD MEMBER [NT AUTHORITY\ANONYMOUS LOGON]
GO

-- Allows CONNECT to [SourceDB].
GRANT CONNECT
    TO [NT AUTHORITY\ANONYMOUS LOGON]
GO
 
-- Allows RECEIVE from the queue for the external actvator app.
GRANT RECEIVE
    ON [TrackingNotificationQueue]
    TO [NT AUTHORITY\ANONYMOUS LOGON]
GO
 
-- Allows VIEW DEFINITION right on the service for the external activator app.
GRANT VIEW DEFINITION
    ON SERVICE::[TrackingNotificationService]
    TO [NT AUTHORITY\ANONYMOUS LOGON]
GO
 
-- Allows REFRENCES right on the queue schema for the external activator app.
GRANT REFERENCES
    ON SCHEMA::dbo
    TO [NT AUTHORITY\ANONYMOUS LOGON]
GO
```

The scripts above give permissions to both `NT SERVICE\SSBExternalActivator` and `NT AUTHORITY\ANONYMOUS LOGON` to access to `TrackingNotificationService` and `TrackingNotificationQueue`. By granting permissions like this, the EA application can receive messages from SB.

---
So far, we have created service broker objects. In the next post, [Step 3: External Activator Application Development](http://devkimchi.com/891/service-broker-external-activator-for-sql-server-step-by-step-3/), we will develop an application to consume the messages sent from SB.
