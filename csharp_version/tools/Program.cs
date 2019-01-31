using System;
using System.Security.Cryptography;
using System.IO;
using System.Text;
using System.Net;
using System.Net.Http;
using System.Collections.Generic;
using System.Threading;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace tools
{
    class Program
    {
        static string cmd;
        static string target;
        static int workingThreads;
        static string url;
        static ulong start;
        static ulong stop;

        static void Main(string[] args)
        {
            cmd = args[0];
            target = args[1];

            Directory.SetCurrentDirectory(target);
            foreach (string arg in args)
            {
                if (arg.StartsWith("-t"))
                {
                    workingThreads = Convert.ToInt32(arg.Remove(0, 2));
                }
                else if (arg.StartsWith("-u"))
                {
                    url = arg.Remove(0, 2);
                }
                else if (arg.StartsWith("-r"))
                {
                    string[] arr = arg.Remove(0, 2).Split("-");
                    start = Convert.ToUInt64(arr[0]);
                    stop = Convert.ToUInt64(arr[1]);

                }
            }

            switch (cmd)
            {
                case "md5":
                    string[] files = Directory.GetFiles(".", "*", SearchOption.AllDirectories);
                    using (MD5 md5Hash = MD5.Create())
                    {
                        foreach (string file in files)
                        {
                            FileStream fileStream = new FileStream(file, FileMode.Open, FileAccess.Read, FileShare.Read);
                            Console.WriteLine(GetMd5Hash(md5Hash, fileStream) + " " + file);
                            fileStream.Close();
                            fileStream.Dispose();
                        }
                    }
                    break;
                case "verify":
                    files = File.ReadAllLines(target);
                    using (MD5 md5Hash = MD5.Create())
                    {
                        foreach (string file in files)
                        {
                            string[] arr = file.Split(' ');
                            FileStream fileStream = new FileStream(arr[1], FileMode.Open, FileAccess.Read, FileShare.Read);
                            if (!VerifyMd5Hash(md5Hash, fileStream, arr[0])) Console.WriteLine(arr[1]);
                            fileStream.Close();
                            fileStream.Dispose();
                        }
                    }
                    break;
                case "update":
                    files = Directory.GetFiles(".", "*", SearchOption.AllDirectories);
                    Queue<string> dlQueue = new Queue<string>(files);
                    ThreadPool.SetMinThreads(workingThreads, workingThreads);
                    for (int i = 0; i < workingThreads; i++)
                    {
                        ThreadPool.QueueUserWorkItem(new WaitCallback(Update), dlQueue);
                    }
                    while (dlQueue.Count > 0)
                    {
                        Console.WriteLine("{0}/{1}", files.Length - dlQueue.Count, files.Length);
                        Thread.Sleep(10000);
                    }
                    Console.WriteLine("{0}/{1}", files.Length - dlQueue.Count, files.Length);
                    Console.ReadKey();
                    break;
                case "rangedl":
                    ranggedl_i = start;
                    ThreadPool.SetMinThreads(workingThreads, workingThreads);
                    for (int i = 0; i < workingThreads; i++)
                    {
                        ThreadPool.QueueUserWorkItem(new WaitCallback(RangeDl), null);
                    }
                    while (ranggedl_i < stop)
                    {
                        Console.WriteLine("{0}/{1}", ranggedl_i, stop);
                        Thread.Sleep(10000);
                    }
                    Console.WriteLine("{0}/{1}", ranggedl_i, stop);
                    Console.ReadKey();
                    break;
                case "smartupd":
                    List<Tuple<string, int>> rules = new List<Tuple<string, int>>();  //带通配符文件名，通配符长度 smartupd用到
                    //Dictionary<string, int> rules = new Dictionary<string, int>();  
                    files = Directory.GetFiles(".", "*", SearchOption.AllDirectories);
                    Regex reg = new Regex(@"-?[1-9]\d*");   //整数
                    foreach (string file in files)
                    {
                        string fileName = Path.GetFileName(file);
                        Match match = reg.Match(fileName);
                        if (match.Success)
                        {
                            string rule = Path.GetDirectoryName(file) + "/" + reg.Replace(fileName, "*");
                            bool exists = false;
                            foreach (Tuple<string, int> tuple in rules)
                            {
                                if (tuple.Item1 == rule)
                                {
                                    exists = true;
                                    break;
                                }
                            }
                            //todo match.Length < 7
                            if (!exists)
                            {
                                rules.Add(new Tuple<string, int>(rule, match.Length));
                            }
                        }
                    }
                    int count = rules.Count;
                    ThreadPool.SetMinThreads(workingThreads, workingThreads);
                    for (int i = 0; i < workingThreads; i++)
                    {
                        ThreadPool.QueueUserWorkItem(new WaitCallback(SmartUpdate), rules);
                    }
                    while (rules.Count > 0 && ranggedl_i <= max)
                    {
                        Console.WriteLine("{0}/{1} {2}/{3}", count - rules.Count, count, ranggedl_i, max);
                        GC.Collect();
                        Thread.Sleep(10000);
                    }
                    Console.WriteLine("{0}/{1} {3}/{4}", count - rules.Count, count, ranggedl_i, max);
                    Console.ReadKey();
                    break;
                default:
                    break;
            }
        }


        static ulong GiveMaxNum(int length)
        {
            ulong max = 0;
            for (int i = 0; i < length; i++)  //生成全是9数字
            {
                max += (ulong)Math.Pow(10, i) * 9;
            }
            return max;
        }

        static ulong max = 0; //预测序号，多线程工作时当前规则的最大值
        static ulong ranggedl_i;
        static object dlQueue_lock = new object();

        async static void SmartUpdate(object obj)
        {
            List<Tuple<string, int>> rules = (List<Tuple<string, int>>)obj;
            while (true)
            {
                string file;
                ulong i;
                lock (dlQueue_lock)
                {
                    if (rules.Count > 0)
                    {
                        file = rules[0].Item1;
                        max = GiveMaxNum(rules[0].Item2);
                        if (ranggedl_i <= max)
                        {
                            i = ranggedl_i;
                            ranggedl_i++;
                        }
                        else
                        {
                            ranggedl_i = 0;
                            rules.RemoveAt(0);
                            continue;
                        }
                    }
                    else
                    {
                        return;
                    }
                }

                file = file.Replace("*", Convert.ToString(i));
                try
                {
                    await Download("http://61mole.61.com/" + file, file);
                }
                catch (WebException e)
                {
                    File.Delete(file);
                    if (e.Response != null)
                    {
                        if (((HttpWebResponse)e.Response).StatusCode != HttpStatusCode.NotFound)
                        {
                            Console.WriteLine(((HttpWebResponse)e.Response).StatusCode + "" + e.Response.ResponseUri.AbsolutePath + "\n" + e.Message);
                        }
                        e.Response.Close();
                        e.Response.Dispose();
                    }
                    else
                    {
                        throw;
                    }
                }
            }
        }

        async static void RangeDl(object obj)
        {
            ulong i;
            while (true)
            {
                lock (dlQueue_lock)
                {
                    if (ranggedl_i <= stop)
                    {
                        i = ranggedl_i;
                        ranggedl_i++;
                    }
                    else
                    {
                        return;
                    }
                }

                string url = Program.url.Replace("*", Convert.ToString(i));
                string file = target.Replace("*", Convert.ToString(i));
                try
                {
                    await Download("http://61mole.61.com/" + url, file);
                }
                catch (WebException e)
                {
                    File.Delete(file);
                    if (((HttpWebResponse)e.Response).StatusCode != HttpStatusCode.NotFound)
                    {
                        Console.WriteLine(((HttpWebResponse)e.Response).StatusCode + "" + e.Response.ResponseUri.AbsolutePath + "\n" + e.Message);
                    }
                }
            }
        }

        async static void Update(object obj)
        {
            Queue<string> dlQueue = (Queue<string>)obj;
            string file;
            while (true)
            {
                lock (dlQueue_lock)
                {
                    if (dlQueue.Count > 0)
                    {
                        file = dlQueue.Dequeue();
                    }
                    else
                    {
                        return;
                    }
                }
                bool exists = File.Exists(file);
                try
                {
                    await Download("http://61mole.61.com/" + file, file);
                }
                catch (WebException e)
                {
                    File.Delete(file);
                    if (((HttpWebResponse)e.Response).StatusCode == HttpStatusCode.NotFound)
                    {
                        if (exists)
                        {
                            Console.WriteLine("rm " + e.Response.ResponseUri.AbsolutePath);
                        }
                    }
                    else
                    {
                        throw;
                    }
                }
            }
        }

        static async Task Download(string url, string filePath)
        {
            HttpWebRequest req = HttpWebRequest.CreateHttp(url);
            HttpWebResponse res = (HttpWebResponse)await req.GetResponseAsync();
            Stream fileStream = new FileStream(filePath, FileMode.Create, FileAccess.Write, FileShare.None);
            Stream resStream = res.GetResponseStream();
            await resStream.CopyToAsync(fileStream);
            fileStream.Close();
            fileStream.Dispose();
            resStream.Close();
            resStream.Dispose();
            res.Close();
            res.Dispose();
        }

        static string GetMd5Hash(MD5 md5Hash, Stream input)
        {

            // Convert the input string to a byte array and compute the hash.
            byte[] data = md5Hash.ComputeHash(input);

            // Create a new Stringbuilder to collect the bytes
            // and create a string.
            StringBuilder sBuilder = new StringBuilder();

            // Loop through each byte of the hashed data 
            // and format each one as a hexadecimal string.
            for (int i = 0; i < data.Length; i++)
            {
                sBuilder.Append(data[i].ToString("x2"));
            }

            // Return the hexadecimal string.
            return sBuilder.ToString();
        }

        // Verify a hash against a string.
        static bool VerifyMd5Hash(MD5 md5Hash, Stream input, string hash)
        {
            // Hash the input.
            string hashOfInput = GetMd5Hash(md5Hash, input);

            // Create a StringComparer an compare the hashes.
            StringComparer comparer = StringComparer.OrdinalIgnoreCase;

            if (0 == comparer.Compare(hashOfInput, hash))
            {
                return true;
            }
            else
            {
                return false;
            }
        }
    }
}
