using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Xml;
using System.Xml.Linq;

namespace SbeaSample.ConsoleApp
{
    public static class Program
    {
        /// <summary>
        /// Database server for source DB.
        /// </summary>
        private static string _sourceServer = ConfigurationManager.AppSettings["SourceServer"];

        /// <summary>
        /// Database name for source DB.
        /// </summary>
        private static readonly string _sourceDb = ConfigurationManager.AppSettings["SourceDb"];

        /// <summary>
        /// Database server for tracking DB.
        /// </summary>
        private static readonly string _trackingServer = ConfigurationManager.AppSettings["TrackingServer"];

        /// <summary>
        /// Database name for tracking DB.
        /// </summary>
        private static readonly string _trackingDb = ConfigurationManager.AppSettings["TrackingDb"];

        /// <summary>
        /// Name for message queue schema.
        /// </summary>
        private static readonly string _messageQueueSchema = ConfigurationManager.AppSettings["MessageQueueSchema"];

        /// <summary>
        /// Name for message queue.
        /// </summary>
        private static readonly string _messageQueueName = ConfigurationManager.AppSettings["MessageQueueName"];

        /// <summary>
        /// Application name used when connecting to SQL Server.
        /// </summary>
        private static readonly string _applicationName = ConfigurationManager.AppSettings["ApplicationName"];

        /// <summary>
        /// Timeout value in milliseconds for the <c>RECEIVE</c> statement to wait for messages.
        /// </summary>
        private static readonly int _waitforTimeout = Convert.ToInt32(ConfigurationManager.AppSettings["WaitForTimeout"]);

        /// <summary>
        /// SQL Server message type name for predefined end dialog messages.
        /// </summary>
        private static readonly string _endDialogMessageType = ConfigurationManager.AppSettings["EndDialogMessageType"];

        /// <summary>
        /// SQL Server message type name for predefined conversation error messages.
        /// </summary>
        private static readonly string _errorMessageType = ConfigurationManager.AppSettings["ErrorMessageType"];

        /// <summary>
        /// Error log file path.
        /// </summary>
        private static readonly string _errorLogPath = ConfigurationManager.AppSettings["ErrorLogPath"];

        /// <summary>
        /// Source DB connection string builder.
        /// </summary>
        private static readonly SqlConnectionStringBuilder _csbSource = new SqlConnectionStringBuilder();

        /// <summary>
        /// Tracking DB connection string builder.
        /// </summary>
        private static readonly SqlConnectionStringBuilder _csbTracking = new SqlConnectionStringBuilder();

        /// <summary>
        /// The main entry point of this console application.
        /// </summary>
        /// <param name="args">List of arguments input from the user.</param>
        public static void Main(string[] args)
        {
            _csbSource.ApplicationName = _applicationName;
            _csbSource.DataSource = _sourceServer;
            _csbSource.InitialCatalog = _sourceDb;
            _csbSource.IntegratedSecurity = true;
            _csbSource.MultipleActiveResultSets = true;

            _csbTracking.ApplicationName = _applicationName;
            _csbTracking.DataSource = _trackingServer;
            _csbTracking.InitialCatalog = _trackingDb;
            _csbTracking.IntegratedSecurity = true;
            _csbTracking.MultipleActiveResultSets = true;

            try
            {
                ProcessMessage();
            }
            catch (Exception ex)
            {
                var sb = new StringBuilder();
                sb.AppendLine("----------");
                sb.AppendLine(ex.Message);
                sb.AppendLine();
                sb.AppendLine(ex.StackTrace);
                sb.AppendLine("==========");

                File.AppendAllText(String.Format(_errorLogPath, DateTime.Today), sb.ToString());
            }
        }

        private static void ProcessMessage()
        {
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
                        command.Transaction = transaction;
                        command.CommandText =
                            String.Format("WAITFOR (RECEIVE TOP(1) conversation_handle, message_type_name, message_body FROM {0}.{1}), TIMEOUT {2}",
                                          BracketizeName(_messageQueueSchema), BracketizeName(_messageQueueName), _waitforTimeout);

                        using (var reader = command.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                messageReceived = true;

                                var conversationHandle = reader.GetGuid(0);
                                var messageTypeName = reader.GetString(1);
                                var messageBody = reader.GetSqlBinary(2);

                                if (messageTypeName == _errorMessageType || messageTypeName == _endDialogMessageType)
                                {
                                    if (messageTypeName == _errorMessageType)
                                    {
                                        // Handle error messages.
                                    }

                                    using (var endConversationCommand = conn.CreateCommand())
                                    {
                                        endConversationCommand.Transaction = transaction;
                                        endConversationCommand.CommandText = "END CONVERSATION @handle";
                                        endConversationCommand.Parameters.Add(new SqlParameter("@handle", conversationHandle));
                                        endConversationCommand.ExecuteNonQuery();
                                    }
                                }
                                else
                                {
                                    try
                                    {
                                        using (var stream = new MemoryStream(messageBody.Value))
                                        using (var sendCommand = conn.CreateCommand())
                                        {
                                            var xml = XDocument.Load(stream);
                                            var result = SaveTrackingDetails(xml);

                                            sendCommand.CommandText = "SEND ON CONVERSATION @handle MESSAGE TYPE [TrackingResponse] (@body)";
                                            sendCommand.Parameters.Add(new SqlParameter("@handle", conversationHandle));
                                            sendCommand.Parameters.Add(new SqlParameter("@body", result));
                                            sendCommand.ExecuteNonQuery();
                                        }
                                    }
                                    catch (Exception ex)
                                    {
                                        var sb = new StringBuilder();
                                        sb.AppendLine("----------");
                                        sb.AppendLine(ex.Message);
                                        sb.AppendLine();
                                        sb.AppendLine(ex.StackTrace);
                                        sb.AppendLine("==========");

                                        File.AppendAllText(String.Format(_errorLogPath, DateTime.Today), sb.ToString());
                                        throw;
                                    }
                                }
                            }
                        }
                        transaction.Commit();
                    }
                } while (messageReceived);
            }
        }

        /// <summary>
        /// Wraps the given Sql Server sysname in brackets and escapes any closing brackets already present in the name.
        /// </summary>
        private static string BracketizeName(string sysname)
        {
            return String.Format("[{0}]", sysname.Replace("]", "]]"));
        }

        private static string SaveTrackingDetails(XDocument xml)
        {

            return "Saved";
        }
    }
}
