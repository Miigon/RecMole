
var status_text;
var flash_content;
var token;
var id;
var amount;
//const flash = "<body><embed type='application/x-shockwave-flash' allowFullScreen='true' quality='high' width='960' height='560' allowScriptAccess='always' id='mymovie_em' name='mymovie_em' src='./rcmgame/{!TOKEN}/Client.swf'></embed></body>";
const rcmgame_url = "./rcmgame/{!TOKEN}/index.html"
function setStatusText(text)
{
    status_text.innerHTML = text;
}

function recOnLoad()
{
    status_text = document.getElementById("status-text");
    flash_content = document.getElementById("flash_content");
    setStatusText("若您愿意帮助 RecMole 获取官方资源文件，为这个拯救童年的回忆的项目出一份力，请点击下面的按钮开始吧。");
}

function start()
{
    document.getElementById("start-button").style.display = "none";
    setStatusText("正在请求 token 中");
    getToken();
}

function getToken()
{
    var xhttp = new XMLHttpRequest();
    xhttp.onreadystatechange = function()
    {
        if (this.readyState == 4 && this.status == 200)
        {
            token = this.responseText;
            loadGame();
        }
    };
    xhttp.open("GET", "/recmoleapi/new_token", true);
    xhttp.send();
}

function loadGame()
{
    refreshToken();
    setInterval(10000,refreshToken);
    flash_content.style.display = "inline-block";
    flash_content.src = rcmgame_url.replace("{!TOKEN}",token);
}

function refreshToken()
{
    var xhttp = new XMLHttpRequest();
    xhttp.timeout = 5000;
    xhttp.ontimeout = function ()
    {
        setStatusText("请求状态失败：超时。");
    }
    xhttp.onreadystatechange = function () 
    {
        if(this.readyState == 4)
        switch(this.status)
        {
            case 200:
            {
                var texts = this.responseText.split(",");
                id = texts[0]
                amount = texts[1]
                if(id == "null") // 未登录
                {
                    setStatusText("请使用验证码： " + token + " 登录游戏。");
                }
                else
                {
                    setStatusText("你好 [" + id + "] 你贡献的文件数：" + amount)
                }
                break;
            }
            case 500:
            {
                if(this.responseText == "Invaild token.")
                {
                    alert("Token 已失效，请重新登录！");
                    window.location.reload();
                }
                else
                {
                    setStatusText("请求状态时发生错误：" + this.responseText);
                }
                break;
            }
        }
    };
    xhttp.open("GET", "/recmoleapi/refresh_session?token="+token, true);
    xhttp.send();

}

window.onload = recOnLoad