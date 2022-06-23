using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AzureSql
{
    internal class Program
    {
        

        static void Main(string[] args)
        {
            DateTime startTime = DateTime.Now;

            Console.WriteLine("Please wait executing 50 requests ...");
            MainAsync().GetAwaiter().GetResult();
            Console.WriteLine("Total Seconds:" + (DateTime.Now - startTime).TotalSeconds.ToString());
            Console.Read();
            
        }

        private static async Task MainAsync()
        {
            var client = new System.Net.Http.HttpClient();
            var tasks = new List<Task<string>>();
            
            var response = "";

            for (int i = 1; i < 51; i++)
            {
                async Task<string> func()
                {
                    using (SqlConnection cnn = new SqlConnection("Server=reprodb.database.windows.net;Database=repro-db;user id=repro_user;password='RAepro_swoddrd123!@';MultipleActiveResultSets=True;Pooling=false"))
                    {
                        using (SqlCommand cmd = new SqlCommand("Select @@VERSION as Ver", cnn))
                        {
                            cnn.Open();
                            SqlDataReader dr = await cmd.ExecuteReaderAsync(CommandBehavior.CloseConnection);
                            
                            while (await dr.ReadAsync())
                            {
                                response = dr["Ver"].ToString();
                            }
                        }


                    }

                    return response;
                }

                tasks.Add(func());
            }

            await Task.WhenAll(tasks);


            foreach (var t in tasks)
            {
                var postResponse = await t; //t.Result would be okay too.
                Console.WriteLine(postResponse);
            }

        }
    }
}
