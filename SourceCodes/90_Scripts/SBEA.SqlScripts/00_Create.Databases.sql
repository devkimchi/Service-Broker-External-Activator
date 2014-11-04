/*
	**	00. Creates databases
		01. Creates tables
		02. Creates stored procedures
		03. Creates service broker objects
		04. Creates triggers
		05. Grant permissions
*/

USE [master]
GO

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'SourceDB')
BEGIN
	DROP DATABASE [SourceDB]
END

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'TrackingDB')
BEGIN
	DROP DATABASE [TrackingDB]
END

CREATE DATABASE [SourceDB]
GO

CREATE DATABASE [TrackingDB]
GO
