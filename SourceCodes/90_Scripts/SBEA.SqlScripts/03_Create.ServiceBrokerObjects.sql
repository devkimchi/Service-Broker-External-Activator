/*
		00. Creates databases
		01. Creates tables
		02. Creates stored procedures
	**	03. Creates service broker objects
		04. Creates triggers
		05. Grant permissions
*/

USE [SourceDB]
GO

-- Turns on the service broker feature.
-- NOTE: This statement will roll back any open transactions.
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'SourceDB' AND is_broker_enabled = 0)
BEGIN
	ALTER DATABASE [SourceDB] SET NEW_BROKER WITH ROLLBACK IMMEDIATE
END
GO

-- Drops existing service broker objects in order of:
-- Events, Services, Queues, Contracts and Message Types

-- Drops events.
IF EXISTS (SELECT * FROM sys.event_notifications WHERE name = 'TrackingEventNotification')
BEGIN
	DROP EVENT NOTIFICATION [TrackingEventNotification]
		ON QUEUE [TrackingRequestQueue]
END

-- Drops services.
IF EXISTS (SELECT * FROM sys.services WHERE name = 'TrackingInitiatorService')
BEGIN
	DROP SERVICE [TrackingInitiatorService]
END

IF EXISTS (SELECT * FROM sys.services WHERE name = 'TrackingTargetService')
BEGIN
	DROP SERVICE [TrackingTargetService]
END

IF EXISTS (SELECT * FROM sys.services WHERE name = 'TrackingNotificationService')
BEGIN
	DROP SERVICE [TrackingNotificationService]
END

-- Drops queues.
IF EXISTS (SELECT * FROM sys.service_queues WHERE name = 'TrackingRequestQueue')
BEGIN
	DROP QUEUE [TrackingRequestQueue]
END

IF EXISTS (SELECT * FROM sys.service_queues WHERE name = 'TrackingResponseQueue')
BEGIN
	DROP QUEUE [TrackingResponseQueue]
END

IF EXISTS (SELECT * FROM sys.service_queues WHERE name = 'TrackingNotificationQueue')
BEGIN
	DROP QUEUE [TrackingNotificationQueue]
END

-- Drops contracts.
IF EXISTS (SELECT * FROM sys.service_contracts WHERE name = 'TrackingContract')
BEGIN
	DROP CONTRACT [TrackingContract]
END

-- Drops message types.
IF EXISTS (SELECT * FROM sys.service_message_types WHERE name = 'TrackingRequest')
BEGIN
	DROP MESSAGE TYPE [TrackingRequest]
END

IF EXISTS (SELECT * FROM sys.service_message_types WHERE name = 'TrackingResponse')
BEGIN
	DROP MESSAGE TYPE [TrackingResponse]
END

-- Creates new service broker objects in order of:
-- Message Types, Contracts, Queues, Services and Events

-- Message type to send requests to the external activator app.
CREATE MESSAGE TYPE [TrackingRequest]
	VALIDATION = WELL_FORMED_XML
GO

-- Message type to receive response from the external activator app.
CREATE MESSAGE TYPE [TrackingResponse]
	VALIDATION = NONE	
GO

-- Contract for conversation.
-- NOTE: INITIATOR is the service broker and TARGET is the external activator app.
CREATE CONTRACT [TrackingContract] (
	[TrackingRequest]	SENT BY INITIATOR, 
	[TrackingResponse]	SENT BY TARGET
	)
GO

-- Queue to store request messages.
CREATE QUEUE [TrackingRequestQueue]
	WITH
		STATUS = ON,
		RETENTION = OFF
	ON [PRIMARY]
GO

-- Queue to store response messages.
CREATE QUEUE [TrackingResponseQueue]
	WITH 
		STATUS = ON,
		RETENTION = OFF,
		ACTIVATION (
			STATUS = ON,
			PROCEDURE_NAME = [usp_GetTrackingResponse],
			MAX_QUEUE_READERS = 10,
			EXECUTE AS SELF)
	ON [PRIMARY]
GO

-- Queue for the external activator app to monitor.
-- The external activator app catches jobs to be done when messages arrive in this queue.
CREATE QUEUE [TrackingNotificationQueue]
	WITH
		STATUS = ON,
		RETENTION = OFF 
	ON [PRIMARY]
GO

-- Service to handle response queue.
-- NOTE: Initiator service lives on the *RESPONSE* queue.
CREATE SERVICE [TrackingInitiatorService]
	ON QUEUE [TrackingResponseQueue] ([TrackingContract])
GO

-- Service to handle request queue.
-- NOTE: Target service lives on the *REQUEST* queue.
CREATE SERVICE [TrackingTargetService]
	ON QUEUE [TrackingRequestQueue] ([TrackingContract])
GO

-- Service for the external activator app.
-- This uses the default contract for event notifications.
CREATE SERVICE [TrackingNotificationService]
	ON QUEUE [TrackingNotificationQueue] ([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification])
GO

-- Event notification for the external activator app.
-- Event will be raised when messages arrive in the request queue on the target service.
CREATE EVENT NOTIFICATION [TrackingEventNotification]
	ON QUEUE [TrackingRequestQueue]
	FOR QUEUE_ACTIVATION
	TO SERVICE 'TrackingNotificationService', 'current database'
GO

USE [master]
GO
