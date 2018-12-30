local http = require "http"
local url = require "url"
local joinPath = require ("path").join
local normalizePath = require("path").normalize
local fs = require "fs"
local timer = require "timer"
local Response = http.ServerResponse
local res_root = conf.res_dir
local recmole_res_root = "../res_recmole/"
local mimes = require "./mimes"
mimes.default = "application/octet-stream"

local server_name = "resource_server_1"
local msg_suffix = [[


* RecMole Project - ]]..server_name

local no_redirect = 1
local special_redirect_rules = {
    ["/"] = "/index.html",
    ["/index.html"] = no_redirect,
--    ["/config/Server.xml"] = no_redirect, -- 注释本行来直连官方服务器（绕过trafficloggerlogin）
    ["/crossdomain.xml"] = no_redirect,
    ["/missinglist.txt"] = no_redirect,
}

local userdata_dir = "./userdata/"

local token_initial_life = 5*60 -- seconds
local flush_time_interval = 20 * 1000 -- milliseconds
local token_cleaner_interval = 2 * 60 * 1000 -- milliseconds
local user_data_saving_interval = 5 * 60 * 1000 -- milliseconds
local keepalive_life = token_initial_life -- seconds

function getType(path)
    return mimes[path:lower():match("[^.]*$")] or mimes.default
end

function Response:notFound(path,reason)
    local resp = self
    local reply = "404 Not Found:\n" .. reason .. msg_suffix
    resp:writeHead(404, {
        ["Content-Type"] = "text/plain",
        ["Content-Length"] = #reply
    })
    resp:write(reply)
end

function Response:error(reason)
    self:writeHead(500, {
        ["Content-Type"] = "text/plain",
        ["Content-Length"] = #reason
    })
    self:write(reason)
end

function Response:okText(text)
    self:writeHead(200, {
        ["Content-Type"] = "text/plain",
        ["Content-Length"] = #text
    })
    self:write(text)
end

-- duplist and missinglist
local duplist = {}
missinglist,err = io.open("missinglist.txt","a+");
if not missinglist then
	print("\27[31mFailed to open missinglist.txt: ",err,"\27[0m")
	os.exit();
end
local ln = 0
missinglist:seek("set");
for line in missinglist:lines() do
	ln = ln + 1
	duplist[line] = true
end
print(ln.." lines of missinglist data has been loaded.")
missinglist:seek("end");

local policy_file = "\
<?xml version=\"1.0\"?><!DOCTYPE cross-domain-policy><cross-domain-policy>\
<allow-access-from domain=\"*\" to-ports=\"*\" /></cross-domain-policy>\000\
"

function Response.file(res,path,dest)
    fs.stat(path, function (err, stat)
        if err then
            if err.code == "ENOENT" then
                return res:notFound(dest,err.message .. "\n")
            end
            if err:sub(1,6) == "ENOENT" then
                return res:notFound(dest,err .. "\n")
            end
            p(err)
            return res:error((err.message or tostring(err)) .. "\n")
        end
        if stat.type ~= "file" then
            return res:notFound(dest,"Not a file\n")
        end
        -- 文件存在
        res:writeHead(200, {
            ["Content-Type"] = getType(path),
            ["Content-Length"] = stat.size
        })
        local stream = fs.createReadStream(path):pipe(res)
        
    end)
end

function Response.redirect(res,dest)
    res:writeHead(307, {
        ["Location"] = dest,
    })
    res:write("")
end

http.createServer(function(req, res)
    req.uri = url.parse(req.url)
    local dest = req.uri.pathname
    if dest == "/crossdomain.xml" then
        res:okText(policy_file)
        return
    end
    if normalizePath(dest):find("%.%.") ~= nil then --avoid path traversal vulnerability
        res:error("Invaild path. " .. msg_suffix)
        return
    end
    -- RecMole API
    if dest:sub(1,11) == "/recmoleapi" then
        if dest == "/recmoleapi/get_amount" then -- dont need a query
            res:okText(tostring(ln))
        else
            res:error("Invaild API.")
        end
        return
    end
    local token
    if dest:sub(1,9) == "/rcmgame/" then
        dest = dest:sub(10,-1)
        local path = joinPath(res_root,dest)
        --print("\27[1;37mAccess",dest,"\27[0m")
        local special_redirect_rule = special_redirect_rules[dest];
        if special_redirect_rule == no_redirect then
            res:file(path,dest)
        elseif special_redirect_rule ~= nil then
            res:redirect(special_redirect_rule)
        else
            if not duplist[dest] then
                print("\27[32mnew file:",dest,"\27[0m")
                missinglist:write(dest,'\n')
                duplist[dest] = true
                ln = ln + 1
            end
            res:writeHead(307, {
                ["Location"] = 'http://51mole.61.com'..dest,
            })
            res:write("")
        end
    else
        local path = joinPath(recmole_res_root,dest)
        if path == recmole_res_root then
            path = joinPath(recmole_res_root,"/index.html")
        end
        res:file(path,dest)
    end
end):listen(conf.ressrv_port)

math.randomseed(os.time())

timer.setInterval(flush_time_interval,function()missinglist:flush()end)
print("\27[36mRedirect resource server started on \27[1mhttp://localhost:"..conf.ressrv_port.."/\27[0m")
