USE [master]
GO

INSERT INTO [SourceDB].[dbo].[Products] ([Name], [Description], [Price]) VALUES ('Product 1', 'Description 1', 10)

SELECT * FROM [SourceDB].[dbo].[TrackingRequestQueue]
SELECT * FROM [SourceDB].[dbo].[TrackingResponseQueue]
SELECT * FROM [SourceDB].[dbo].[TrackingNotificationQueue]

INSERT INTO [SourceDB].[dbo].[Products] ([Name], [Description], [Price]) VALUES ('Product 2', 'Description 2', 20)

SELECT * FROM [SourceDB].[dbo].[TrackingRequestQueue]
SELECT * FROM [SourceDB].[dbo].[TrackingResponseQueue]
SELECT * FROM [SourceDB].[dbo].[TrackingNotificationQueue]

INSERT INTO [SourceDB].[dbo].[Products] ([Name], [Description], [Price]) VALUES ('Product 3', 'Description 3', 30)

SELECT * FROM [SourceDB].[dbo].[TrackingRequestQueue]
SELECT * FROM [SourceDB].[dbo].[TrackingResponseQueue]
SELECT * FROM [SourceDB].[dbo].[TrackingNotificationQueue]

UPDATE [SourceDB].[dbo].[Products] SET [Price] = 19.99 WHERE ProductId = 2

SELECT * FROM [SourceDB].[dbo].[TrackingRequestQueue]
SELECT * FROM [SourceDB].[dbo].[TrackingResponseQueue]
SELECT * FROM [SourceDB].[dbo].[TrackingNotificationQueue]

DELETE FROM [SourceDB].[dbo].[Products] WHERE ProductId = 3

SELECT * FROM [SourceDB].[dbo].[TrackingRequestQueue]
SELECT * FROM [SourceDB].[dbo].[TrackingResponseQueue]
SELECT * FROM [SourceDB].[dbo].[TrackingNotificationQueue]
