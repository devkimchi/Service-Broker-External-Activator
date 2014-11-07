/*
		00. Creates databases
		01. Creates tables
	**	02. Creates stored procedures
		03. Creates service broker objects
		04. Creates triggers
		05. Grant permissions
*/
USE [SourceDB]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_SendTrackingRequest')
BEGIN
	DROP PROCEDURE [usp_SendTrackingRequest]
END

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_GetTrackingResponse')
BEGIN
	DROP PROCEDURE [usp_GetTrackingResponse]
END

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- Sends tracking request message to the queue.
CREATE PROCEDURE [usp_SendTrackingRequest]
	@productId		AS INT,
	@trackingType	AS NVARCHAR(8),
	@inserted		AS XML,
	@deleted		AS XML
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @data	AS XML

	SET @data = (SELECT
					@productId				AS ProductId,
					@trackingType			AS TrackingType,
					COALESCE(@inserted, '')	AS Inserted,
					COALESCE(@deleted, '')	AS Deleted
				 FOR XML PATH(''), ROOT('Changes'), ELEMENTS)

	DECLARE @handle	AS UNIQUEIDENTIFIER

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

-- Gets the tracking response message from the queue.
CREATE PROCEDURE [usp_GetTrackingResponse]
AS
BEGIN

	SET NOCOUNT ON;

    DECLARE @handle	AS UNIQUEIDENTIFIER

    WAITFOR (
		RECEIVE
			TOP(1) @handle = CONVERSATION_HANDLE
		FROM
			[dbo].[TrackingResponseQueue]
	), TIMEOUT 10000
		
    IF @handle IS NULL
	BEGIN
		RETURN
	END

    END CONVERSATION @handle;

END
GO

USE [master]
GO
