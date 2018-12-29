
var status_text;
var flash_content;
//const flash = "<body><embed type='application/x-shockwave-flash' allowFullScreen='true' quality='high' width='960' height='560' allowScriptAccess='always' id='mymovie_em' name='mymovie_em' src='./rcmgame/{!TOKEN}/Client.swf'></embed></body>";
const rcmgame_url = "./rcmgame/index.html"
function setStatusText(text)
{
    status_text.innerHTML = text;
}

function recOnLoad()
{
    status_text = document.getElementById("status-text");
    flash_content = document.getElementById("flash_content");
    //setStatusText("若您愿意帮助 RecMole 获取官方资源文件，为这个拯救童年的回忆的项目出一份力，请点击下面的按钮开始吧。");
    setStatusText("正在请求文件数中");
    refresh_amount();
    setInterval(1000,refresh_amount)
}

function refresh_amount()
{
    var xhttp = new XMLHttpRequest();
    xhttp.onreadystatechange = function()
    {
        if(this.readyState == 4 && this.status == 200)
        {
            setStatusText("目前 RecMole 项目已经拥有文件 " + this.responseText + " 个，期待你的贡献！");
        }
        else
        {
            setStatusText("请求状态时发生错误：" + this.responseText);
        }
    };
    xhttp.timeout = 5000;
    xhttp.open("GET", "/recmoleapi/get_amount", true);
    xhttp.send();
}

function start()
{
    document.getElementById("start-button").style.display = "none";
    loadGame()
}

function loadGame()
{
    flash_content.style.display = "inline-block";
    flash_content.src = rcmgame_url;
}

window.onload = recOnLoad