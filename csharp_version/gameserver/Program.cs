using Newtonsoft.Json.Linq;
using System;
using System.Threading;

namespace gameserver
{
    class Program
    {
        static void Main(string[] args)
        {
            string str_conf = System.IO.File.ReadAllText("config.json");
            JObject conf = JObject.Parse(str_conf);
            ressrv ressrv = new ressrv(conf);

            Console.WriteLine("Hello World!");
            while (true)
            {
                System.Console.ReadKey();
            }

        }
    }
}
