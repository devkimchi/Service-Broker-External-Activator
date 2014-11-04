/*
		00. Creates databases
		01. Creates tables
		02. Creates stored procedures
		03. Creates service broker objects
		04. Creates triggers
	**	05. Grant permissions
*/

-- For this sample, make sure that both [NT SERVICE\SSBExternalActivator] and [NT AUTHORITY\ANONYMOUS LOGON]
-- should be created and get appropriate permissions granted.
-- For PRODUCTION, instead of both accounts, an appropriate service account MUST be used.

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

USE [master]
GO
