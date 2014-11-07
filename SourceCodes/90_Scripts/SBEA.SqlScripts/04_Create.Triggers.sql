/*
		00. Creates databases
		01. Creates tables
		02. Creates stored procedures
		03. Creates service broker objects
	**	04. Creates triggers
		05. Grant permissions
*/
USE [SourceDB]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'TR' AND name = 'trg_INS_Products')
BEGIN
	DROP TRIGGER [trg_INS_Products]
END

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'TR' AND name = 'trg_UPD_Products')
BEGIN
	DROP TRIGGER [trg_UPD_Products]
END

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'TR' AND name = 'trg_DEL_Products')
BEGIN
	DROP TRIGGER [trg_DEL_Products]
END

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[trg_INS_Products]
	ON [dbo].[Products]
	AFTER INSERT
AS
BEGIN

	SET NOCOUNT ON

	DECLARE @productId		AS INT
	DECLARE @trackingType	AS NVARCHAR(8)
	DECLARE @inserted		AS XML
	DECLARE @deleted		AS XML

	SELECT	@productId		= ProductId FROM inserted
	SET		@trackingType	= 'INSERT'
	SET		@inserted		= (SELECT * FROM inserted FOR XML PATH(''), ROOT('Row'), ELEMENTS)
	SET		@deleted		= NULL

	EXECUTE [dbo].[usp_SendTrackingRequest] @productId, @trackingType, @inserted, @deleted

END

GO
CREATE TRIGGER [dbo].[trg_UPD_Products]
	ON [dbo].[Products]
	AFTER UPDATE
AS
BEGIN

	SET NOCOUNT ON

	DECLARE @productId		AS INT
	DECLARE @trackingType	AS NVARCHAR(8)
	DECLARE @inserted		AS XML
	DECLARE @deleted		AS XML

	SELECT	@productId		= ProductId FROM inserted
	SET		@trackingType	= 'UPDATE'
	SET		@inserted		= (SELECT * FROM inserted FOR XML PATH(''), ROOT('Row'), ELEMENTS)
	SET		@deleted		= (SELECT * FROM deleted FOR XML PATH(''), ROOT('Row'), ELEMENTS)

	EXECUTE [dbo].[usp_SendTrackingRequest] @productId, @trackingType, @inserted, @deleted

END
GO

CREATE TRIGGER [dbo].[trg_DEL_Products]
	ON [dbo].[Products]
	AFTER DELETE
AS
BEGIN

	SET NOCOUNT ON

	DECLARE @productId		AS INT
	DECLARE @trackingType	AS NVARCHAR(8)
	DECLARE @inserted		AS XML
	DECLARE @deleted		AS XML

	SELECT	@productId		= ProductId FROM deleted
	SET		@trackingType	= 'DELETE'
	SET		@inserted		= NULL
	SET		@deleted		= (SELECT * FROM deleted FOR XML PATH(''), ROOT('Row'), ELEMENTS)

	EXECUTE [dbo].[usp_SendTrackingRequest] @productId, @trackingType, @inserted, @deleted

END
GO

USE [master]
GO
