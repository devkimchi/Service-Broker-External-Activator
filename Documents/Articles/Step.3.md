# Service Broker External Activator for SQL Server Step by Step #3 #

From the previous post, [Step 2: SQL Server Setup](http://devkimchi.com/831/service-broker-external-activator-for-sql-server-step-by-step-2/), we have created Service Broker (SB) objects including stored procedures and triggers. In this article, we are going to develop the actual application to consume messages.

Its sample source codes can be found at: [devkimchi/Service-Broker-External-Activator](https://github.com/devkimchi/Service-Broker-External-Activator)

> * [Step 1: Service Broker External Activator Service Setup](http://devkimchi.com/811/service-broker-external-activator-for-sql-server-step-by-step-1/)
> * [Step 2: SQL Server Setup](http://devkimchi.com/831/service-broker-external-activator-for-sql-server-step-by-step-2/)
> * **Step 3: External Activator Application Development**
> * [Step 4: External Activator Service Configuration](http://devkimchi.com/951/service-broker-external-activator-for-sql-server-step-by-step-4/)
> * [Step 5: Putting Them Altogether](http://devkimchi.com/1051/service-broker-external-activator-for-sql-server-step-by-step-5/)


## External Activator Application ##

As you can find the complete source code from the [GitHub repository](https://github.com/devkimchi/Service-Broker-External-Activator/blob/master/SourceCodes/02_Apps/SbeaSample.ConsoleApp/Program.cs), the main part of this application is the `ProcessRequests()` method. We will only look through several lines within the method.

```csharp
using (var conn = new SqlConnection(_csbSource.ToString()))
{
    conn.Open();

    bool messageReceived;
    do
    {
        messageReceived = false;
        using (var transaction = conn.BeginTransaction())
        using (var command = conn.CreateCommand())
        {
            ...
        }
    } while (messageReceived);
}
```

As you can see, `do`...`while` loop is performed until `messageReceived` becomes `false`. Let's deep dive into the `do`...`while` loop.

```csharp
command.CommandText = String.Format("WAITFOR (RECEIVE TOP(1) conversation_handle, message_type_name, message_body FROM {0}.{1}), TIMEOUT {2}",
                                    BracketizeName(_messageQueueSchema),
                                    BracketizeName(_messageQueueName),
                                    _waitforTimeout);
```

As mentioned in the [previous post](http://devkimchi.com/831/service-broker-external-activator-for-sql-server-step-by-step-2/#creating-stored-procedures), the stored procedure has sent a request message. With the SQL statement above receives the message.


```csharp
var reader = command.ExecuteReader();
if (!reader.Read())
{
    reader.Dispose();
    transaction.Commit();
    continue;
}
```

If no message is picked up, the application completes the transaction without doing anything. But, a message comes up to the line, it is time to process. In order to keep the code simple, I just omitted error handling logic, but for production, it should be implemented.


```csharp
var conversationHandle = reader.GetGuid(0);
var messageTypeName = reader.GetString(1);
var messageBody = reader.GetSqlBinary(2);

reader.Dispose();

try
{
    if (messageTypeName == _endDialogMessageType || messageTypeName == _errorMessageType)
    {
        if (messageTypeName == _errorMessageType)
        {
            // Handle the error message
        }
    }
    else
    {
        using (var stream = new MemoryStream(messageBody.Value))
        {
            var message = XDocument.Load(stream);
            var responsePayload = ProcessMessage(message);
        }
    }
    EndConversation(conn, transaction, conversationHandle);
    transaction.Commit();
}
catch
{
    EndConversation(conn, transaction, conversationHandle);
    transaction.Commit();
    throw;
}
```

As the message is formatted as XML, the message is populated as `byte` array then converted to an `XDocument` instance for further processing. Once the processing is complete, the conversation is opened by stored procedure should be closed like below:

```csharp
private static void EndConversation(SqlConnection conn, SqlTransaction transaction, Guid conversationHandle)
{
    using (var command = conn.CreateCommand())
    {
        command.Transaction = transaction;
        command.CommandText = "END CONVERSATION @handle";
        command.Parameters.Add(new SqlParameter("@handle", conversationHandle));
        command.ExecuteNonQuery();
    }
}
``` 

You can of course close the conversation by sending the message back to the SQL Server. If you want to close the message in this way, the SQL statement should be instead:

```csharp
command.CommandText = "SEND ON CONVERSATION @handle MESSAGE TYPE [TrackingResponse] (@data)";
command.Parameters.Add(new SqlParameter("@handle", conversationHandle));
command.Parameters.Add(new SqlParameter("@data", data));
```

The last part of this application is to compare and store the changes into the tracking database. This logic can be found at the method, `ProcessMessage(XDocument xml)`. The method handles XML document like [this](https://github.com/devkimchi/Service-Broker-External-Activator/blob/dev/Documents/Samples/SampleMessage.xml). In order to be as simple as possible, this method just uses hard-coded SQL scripts, which is not desirable for production use. For your business requirements, this should be modified &ndash; you can implement this part with Entity Framework, Dependency Injection or whatever you want.


---
We have developed an external activator application to handle messages delivered from SB. In the next article, [Step 4: External Activator Service Configuration](http://devkimchi.com/951/service-broker-external-activator-for-sql-server-step-by-step-4/), we will configure the External Activator Service to actually pass messages to the application from database.
