USE [SourceDB]
GO

INSERT INTO [dbo].[Products] ([Name], [Description], [Price]) VALUES ('Product 1', 'Description 1', 10)
INSERT INTO [dbo].[Products] ([Name], [Description], [Price]) VALUES ('Product 2', 'Description 2', 20)
INSERT INTO [dbo].[Products] ([Name], [Description], [Price]) VALUES ('Product 3', 'Description 3', 30)

UPDATE [dbo].[Products] SET [Price] = 19.99 WHERE ProductId = 2

DELETE FROM [dbo].[Products] WHERE ProductId = 3
