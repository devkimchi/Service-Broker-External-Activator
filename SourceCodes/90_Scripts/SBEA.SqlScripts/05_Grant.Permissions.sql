/*
		00. Creates databases
		01. Creates tables
		02. Creates service broker objects
		03. Creates stored procedures
		04. Creates triggers
	**	05. Grant permissions
*/

-- Assumes that [NT AUTHORITY\ANONYMOUS LOGON] is used.
-- Creates [NT AUTHORITY\ANONYMOUS LOGON] for both databases.
-- NOTE: For production, instead of [NT AUTHORITY\ANONYMOUS LOGON], a service account MUST be used.
USE [TrackingDB]
GO

CREATE USER [NT AUTHORITY\ANONYMOUS LOGON] FOR LOGIN [NT AUTHORITY\ANONYMOUS LOGON]
GO

USE [SourceDB]
GO

CREATE USER [NT AUTHORITY\ANONYMOUS LOGON] FOR LOGIN [NT AUTHORITY\ANONYMOUS LOGON]
GO

-- Allows CONNECT to [SourceDB].
GRANT CONNECT
	TO [NT AUTHORITY\ANONYMOUS LOGON]
GO
 
-- Allows RECEIVE from the queue for the external actvator app.
GRANT RECEIVE
	ON [TrackingExternalActivatorQueue]
	TO [NT AUTHORITY\ANONYMOUS LOGON]
GO
 
-- Allows VIEW DEFINITION right on the service for the external activator app.
GRANT VIEW DEFINITION
	ON SERVICE::[TrackingExternalActivatorService]
	TO [NT AUTHORITY\ANONYMOUS LOGON]
GO
 
-- Allows REFRENCES right on the queue schema for the external activator app.
GRANT REFERENCES
	ON SCHEMA::dbo
	TO [NT AUTHORITY\ANONYMOUS LOGON]
GO
