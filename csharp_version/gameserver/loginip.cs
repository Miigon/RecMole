using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Text;
using System.Threading.Tasks;

namespace gameserver
{
    class loginip
    {
        HttpListener listener = new HttpListener();
        JObject conf;
        public loginip(JObject conf)
        {
            this.conf = conf;
            listener.Prefixes.Add(conf["ressrv_bind"].ToString());
            listener.Start();
            Console.WriteLine("loginip: Listening at " + conf["ressrv_bind"].ToString());
            listener.BeginGetContext(new AsyncCallback(GetContent_Callback), listener);
        }

        async void GetContent_Callback(IAsyncResult ar)
        {
            HttpListenerContext context = listener.EndGetContext(ar);
            HttpListenerRequest req = context.Request;
            using (HttpListenerResponse res = context.Response)
            {
                if (req.Url.AbsolutePath == "/ip.txt")
                {
                    await SendStringAsync(res, conf["login_server_address"].ToString());
                }
                else
                {
                    res.StatusCode = 404;
                    await SendStringAsync(res, "404 Not Found");
                }
                res.Close();
            }
        }

        async Task SendStringAsync(HttpListenerResponse res, string str)
        {
            byte[] buffer = Encoding.UTF8.GetBytes(str);
            res.ContentLength64 = buffer.LongLength;
            res.ContentType = "text/plain";
            using (Stream stream = res.OutputStream)
            {
                await stream.WriteAsync(buffer);
                stream.Close();
            }
        }
    }
}
