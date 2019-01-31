using System;
using System.Collections.Generic;
using System.Text;
using System.Net;
using System.Net.Http;
using Newtonsoft.Json.Linq;
using System.Threading;
using System.IO;
using System.Threading.Tasks;

namespace gameserver
{
    class ressrv
    {
        HttpListener listener = new HttpListener();
        JObject conf;
        public ressrv(JObject conf)
        {
            this.conf = conf;
            listener.Prefixes.Add(conf["ressrv_bind"].ToString());
            listener.Start();
            Console.WriteLine("ressrv: Listening at " + conf["ressrv_bind"].ToString());
            listener.BeginGetContext(new AsyncCallback(GetContent_Callback), listener);
        }

        async void GetContent_Callback(IAsyncResult ar)
        {
            HttpListener listener = (HttpListener)ar.AsyncState;
            listener.BeginGetContext(new AsyncCallback(GetContent_Callback), listener);
            HttpListenerContext context = listener.EndGetContext(ar);

            HttpListenerRequest req = context.Request;
            HttpListenerResponse res = context.Response;

            string filePath = conf["res_dir"].ToString() + req.Url.AbsolutePath;

            if (System.IO.File.Exists(filePath))
            {
                //命中本地缓存
                Console.WriteLine("ressrv: HitCache {0} ", req.RawUrl);
                try
                {
                    using (FileStream fileStream = new FileStream(filePath, FileMode.Open, FileAccess.Read, FileShare.Read))
                    {
                        res.ContentType = Mime.MIME[Path.GetExtension(filePath).TrimStart('.')];
                        res.ContentLength64 = fileStream.Length;
                        await fileStream.CopyToAsync(res.OutputStream);
                    }
                    res.Close();
                    return;
                }
                catch (IOException e)
                {
                    Console.WriteLine("ressrv: Cache IOException {0}\r\n{1}", req.RawUrl, e.Message);
                    //res.StatusCode = 500;
                    //res.Close();
                    //throw;
                }
            }

            #region 请求官方

            //请求官方
            Console.WriteLine("ressrv: proxy {0} ", conf["official_address"] + req.RawUrl);
            HttpWebRequest c_req = HttpWebRequest.CreateHttp(conf["official_address"] + req.RawUrl);
            HttpWebResponse c_res;
            try
            {
                c_res = (HttpWebResponse)await c_req.GetResponseAsync();
            }
            catch (WebException e)
            {
                c_res = (HttpWebResponse)e.Response;
                Console.WriteLine("ressrv: {0} {1} ", (int)c_res.StatusCode, c_res.ResponseUri);
                res.StatusCode = (int)c_res.StatusCode;
                res.Close();
                c_res.Dispose();
                return;
            }

            res.ContentLength64 = c_res.ContentLength;
            res.ContentType = c_res.ContentType;

            Stream c_stream = c_res.GetResponseStream();
            Stream s_stream = res.OutputStream;

            string dirName = Path.GetDirectoryName(filePath);
            if (!Directory.Exists(dirName)) Directory.CreateDirectory(dirName);


            FileStream f_stream = null;
            try
            {
                f_stream = new FileStream(filePath, FileMode.Create, FileAccess.Write, FileShare.None);
            }
            catch (IOException)
            {
                //throw;
            }

            //start copy
            byte[] buffer = new byte[4096];
            Int64 loopCount = 0;
            try
            {
                while (loopCount < c_res.ContentLength)
                {
                    int count = await c_stream.ReadAsync(buffer, 0, buffer.Length);
                    loopCount += count;
                    //返回给client
                    await s_stream.WriteAsync(buffer, 0, count);
                    if (f_stream != null)
                    {
                        //存入本地
                        await f_stream.WriteAsync(buffer, 0, count);
                    }
                    //TODO tcp rst 500

                }
                if (f_stream != null)
                {
                    f_stream.Close();
                    f_stream.Dispose();
                    Console.WriteLine("ressrv: Cached {0}", req.Url.AbsolutePath);
                }
            }
            catch (Exception)
            {

                //throw;
            }
            finally
            {
                f_stream.Close();
                f_stream.Dispose();
                File.Delete(filePath);
                c_stream.Close();
                c_stream.Dispose();
                s_stream.Close();
                s_stream.Dispose();
                c_res.Close();
                c_res.Dispose();
                res.Close();
            }



            #endregion


        }
    }
}
