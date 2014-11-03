/*
		00. Creates databases
		01. Creates tables
		02. Creates service broker objects
	**	03. Creates stored procedures
		04. Creates triggers
		05. Grant permissions
*/
USE [SourceDB]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_SendTrackingRequest')
BEGIN
	DROP PROCEDURE [usp_SendTrackingRequest]
END

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- Stored Procedure which will be used to send the Audit Message to the Queue
-- Error handling has been avoided to keep the sample code brief
CREATE PROCEDURE [usp_SendTrackingRequest]
	@productId		AS INT,
	@trackingType	AS NVARCHAR(8),
	@inserted		AS XML,
	@deleted		AS XML
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @data	AS XML

	SET @data = (SELECT @productId AS ProductId, @trackingType AS TrackingType, @inserted AS Inserted, @deleted AS Deleted FOR XML RAW, ELEMENTS)

	DECLARE @handle	AS UNIQUEIDENTIFIER

	BEGIN DIALOG CONVERSATION @handle  
		FROM
			SERVICE [TrackingInitiatorService]
		TO
			SERVICE '[TrackingTargetService]'
		ON
			CONTRACT [TrackingContract]
		WITH
			ENCRYPTION = OFF;

	SEND
		ON CONVERSATION @handle
		MESSAGE TYPE [TrackingRequest] (@data)

END
GO
