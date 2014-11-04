/*
		00. Creates databases
	**	01. Creates tables
		02. Creates stored procedures
		03. Creates service broker objects
		04. Creates triggers
		05. Grant permissions
*/

USE [SourceDB]
GO

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Products')
BEGIN
	DROP TABLE [Products]
END

CREATE TABLE [dbo].[Products] (
	[ProductId]		[int]			IDENTITY(1,1)	NOT NULL,
	[Name]			[nvarchar](50)					NOT NULL,
	[Description]	[nvarchar](50)					NULL,
	[Price]			[decimal](18, 2)				NOT NULL,
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

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'TrackingLogs')
BEGIN
	DROP TABLE [TrackingLogs]
END

CREATE TABLE [dbo].[TrackingLogs] (
	[TrackingLogId]	[int]			IDENTITY(1,1)	NOT NULL,
	[Source]		[nvarchar](50)					NOT NULL,
	[Field]			[nvarchar](50)					NOT NULL,
	[TrackingType]	[nvarchar](8)					NOT NULL,
	[OldValue]		[nvarchar](MAX)					NULL,
	[NewValue]		[nvarchar](MAX)					NULL,
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

USE [master]
GO
