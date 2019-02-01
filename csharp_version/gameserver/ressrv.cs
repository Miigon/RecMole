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
            HttpListenerContext context = listener.EndGetContext(ar);
            HttpListenerRequest req = context.Request;
            using (HttpListenerResponse res = context.Response)
            {
                string filePath;
                //重定向
                if (redirect_rules(req.Url.AbsolutePath))
                {
                    filePath = conf["res_redirect_dir"].ToString() + req.Url.AbsolutePath;
                }
                else
                {
                    filePath = conf["res_dir"].ToString() + req.Url.AbsolutePath;
                }

                //本地缓存
                if (System.IO.File.Exists(filePath))
                {
                    //命中本地缓存
                    Console.WriteLine("ressrv: HitCache {0} ", req.RawUrl);
                    try
                    {
                        await SendFileAsync(res, filePath);
                        res.Close();
                        return;
                    }
                    catch (IOException e)
                    {
                        Console.WriteLine("ressrv: Cache IOException {0}\r\n{1}", req.RawUrl, e.Message);
                    }
                }

                #region 请求官方
                //请求官方
                Console.WriteLine("ressrv: proxy {0} ", conf["official_address"] + req.RawUrl);
                HttpWebRequest c_req = HttpWebRequest.CreateHttp(conf["official_address"] + req.RawUrl);
                HttpWebResponse c_res = null;

                //尝试连接官方获取c_res对象
                try
                {
                    c_res = (HttpWebResponse)await c_req.GetResponseAsync();
                }
                catch (WebException e)
                {
                    if (e.Response != null)
                    {
                        HttpWebResponse e_res = (HttpWebResponse)e.Response;
                        Console.WriteLine("ressrv: {0} {1} ", (int)e_res.StatusCode, e_res.ResponseUri);
                        res.StatusCode = (int)e_res.StatusCode;
                        e_res.Dispose();
                    }
                    else
                    {
                        Console.WriteLine("ressrv: 502 {0}", e.Message);
                        res.StatusCode = 502;
                    }
                    res.Close();
                    return;
                }
                using (c_res)
                {
                    res.ContentLength64 = c_res.ContentLength;
                    res.ContentType = c_res.ContentType;

                    //尝试获取文件流
                    FileStream f_stream = null;
                    try
                    {
                        string dirName = Path.GetDirectoryName(filePath);
                        if (!Directory.Exists(dirName)) Directory.CreateDirectory(dirName);
                        f_stream = new FileStream(filePath, FileMode.Create, FileAccess.Write, FileShare.None);
                    }
                    catch (IOException)
                    {
                        //throw;
                    }

                    //start copy
                    using (Stream c_stream = c_res.GetResponseStream(), s_stream = res.OutputStream)
                    {
                        try
                        {
                            await CopyStreamAsync(c_stream, s_stream, f_stream);
                            //dispose f_stream
                            if (f_stream != null)
                            {
                                f_stream.Close();
                                f_stream.Dispose();
                                Console.WriteLine("ressrv: Cached {0}", req.Url.AbsolutePath);
                            }
                        }
                        catch (Exception e)
                        {
                            File.Delete(filePath);
                            Console.WriteLine("ressrv: Error {0}", e.Message);
                            res.Abort();
                        }
                        finally
                        {
                            s_stream.Close();
                            c_stream.Close();
                        }
                    }
                    c_res.Close();
                }
                res.Close();

            }

            #endregion
        }


        async Task CopyStreamAsync(Stream source, Stream dest, FileStream file = null)
        {
            byte[] buffer = new byte[4096];
            int count = 0;
            do
            {
                count = await source.ReadAsync(buffer, 0, buffer.Length);
                //返回给client
                await dest.WriteAsync(buffer, 0, count);
                if (file != null)
                {
                    //存入本地
                    await file.WriteAsync(buffer, 0, count);
                }
            } while (count > 0);

        }

        async Task SendFileAsync(HttpListenerResponse res, string filePath)
        {
            using (FileStream fileStream = new FileStream(filePath, FileMode.Open, FileAccess.Read, FileShare.Read))
            {
                res.ContentType = Mime.MIME[Path.GetExtension(filePath).TrimStart('.')];
                res.ContentLength64 = fileStream.Length;
                using (Stream stream = res.OutputStream)
                {
                    await fileStream.CopyToAsync(res.OutputStream);
                    stream.Close();
                }
                fileStream.Close();
            }
        }

        bool redirect_rules(string url)
        {
            switch (url)
            {
                case "/index.html":
                    return true;
                case "/config/Server.xml":
                    return !this.conf["res_official_address"].ToObject<bool>();
                case "/dll/ClientCommonDLL.swf":
                    return this.conf["res_bypass_encrypt"].ToObject<bool>();
                default:
                    return false;
            }
        }
    }
}

