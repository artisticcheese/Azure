using System.Data.SqlClient;
var client = new System.Net.Http.HttpClient();
var tasks = new List<Task<int>>();
var watch = System.Diagnostics.Stopwatch.StartNew();
for (int i = 1; i < 101; i++)
{
   async Task<int> func()
   {

      string connString = "Server=someserver.database.usgovcloudapi.net;Database=Someserver;user id=core360user;password=somepassword;MultipleActiveResultSets=True;Pooling=false;";
      SqlConnection connection = new SqlConnection(connString);
      SqlCommand command = new SqlCommand("Select @@VERSION", connection);
      command.Connection.Open();
      //var response = await client.GetAsync("http://1.1.1.1");
      //var reader = await command.ExecuteNonQueryAsync();
      return await command.ExecuteNonQueryAsync();
   }

   tasks.Add(func());
}

await Task.WhenAll(tasks);
watch.Stop();
Console.WriteLine($"Execution Time: {watch.ElapsedMilliseconds} ms");