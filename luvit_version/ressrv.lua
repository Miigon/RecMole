local http = require "http"
local url = require "url"
local joinPath = require ("path").join
local normalizePath = require("path").normalize
local fs = require "fs"
local timer = require "timer"
local Response = http.ServerResponse
local root = conf.res_dir
local mimes = require "./mimes"
mimes.default = "application/octet-stream"

local server_name = "resource_server_1"
local msg_suffix = [[


* RecMole Project - ]]..server_name

local no_redirect = 1
local special_redirect_rules = {
    ["/"] = "/index.html",
    ["/index.html"] = no_redirect,
    --["/config/Server.xml"] = no_redirect,
    ["/crossdomain.xml"] = no_redirect,
    ["/missinglist.txt"] = no_redirect,
}

local token_initial_life = 5*60 -- seconds
local flush_time_interval = 20 * 1000 -- milliseconds
local token_cleaner_interval = 5 * 60 * 1000 -- milliseconds
local keepalive_set_life = token_initial_life -- seconds

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
ln = 0
missinglist:seek("set");
for line in missinglist:lines() do
	ln = ln + 1
	duplist[line] = true
end
print(ln.." lines of missinglist data has been loaded.")
missinglist:seek("end");

function tokenCharFunction()
    local x = math.random(1,52)
    if x <= 26 then --lowercase
        return string.char(96 + x)
    else -- uppercase
        return string.char(64 + x)
    end
end

function generateToken()
    local token = ""
    for i=0,16 do
        token = token .. tokenCharFunction()
    end
    return token
end

function verifySession(session)
    return session and os.time() < session.start + session.life
end

function refleshSession(session)
    session.life = keepalive_set_life
end

local userList = {[70178614]={amount=1223}}
local sessionList = {}

http.createServer(function(req, res)
    req.uri = url.parse(req.url,true)
    local dest = req.uri.pathname
    if normalizePath(dest):find("%.%.") ~= nil then --avoid path traversal vulnerability
        res:error("Invaild path. " .. msg_suffix)
        return
    end
    -- RecMole API
    if dest:sub(1,11) == "/recmoleapi" then
        if dest == "/recmoleapi/new_token" then -- dont need a query
            local token
            repeat token = generateToken() until sessionList[token] == nil end
            sessionList[token] = {start = os.time(),life = token_initial_life}
            res:okText(tostring(token))
        else -- need a query
            local query = req.uri.query
            if not query then 
                return res:error("Invaild query.")
            end
            if dest == "/recmoleapi/get_amount_by_id" then
                local id = tonumber(query["id"])
                if type(id) ~= "number" then 
                    return res:error("Invaild query.")
                end
                local user = userList[id]
                if user == nil then 
                    return res:error("User not found.")
                end
                res:okText(tostring(user.amount))
            elseif dest == "/recmoleapi/reflesh_session" then
                local token = tostring(query["token"])
                if type(token) ~= "string" then 
                    return res:error("Invaild query.")
                end
                local session = sessionList[token]
                if not verifySession(session) then
                    return res:error("Invaild token.")
                end
                refleshSession(session)

                res:okText(tostring(user.amount))
            end
        else
            res:error("Invaild API.")
        end
        return
    end
    local path = joinPath(root,dest)
    --print("\27[1;37mAccess",dest,"\27[0m")
    local special_redirect_rule = special_redirect_rules[dest];
    if special_redirect_rule == no_redirect then
        fs.stat(path, function (err, stat)
            if err then
                if err.code == "ENOENT" then
                    return res:notFound(req.uri.pathname,err.message .. "\n")
                end
                if err:sub(1,6) == "ENOENT" then
                    return res:notFound(req.uri.pathname,err .. "\n")
                end
                p(err)
                return res:error((err.message or tostring(err)) .. "\n")
            end
            if stat.type ~= "file" then
                return res:notFound(req.uri.pathname,"Requested url is not a file\n")
            end
            -- 文件存在
            res:writeHead(200, {
                ["Content-Type"] = getType(path),
                ["Content-Length"] = stat.size
            })
            local stream = fs.createReadStream(path):pipe(res)
            
        end)
    elseif special_redirect_rule ~= nil then
        res:writeHead(307, {
            ["Location"] = special_redirect_rule,
        })
        res:write("")
    else
        if not duplist[dest] then
			print("\27[32mnew file:",dest,"\27[0m")
			missinglist:write(dest,'\n')
            duplist[dest] = true
		end
        res:writeHead(307, {
            ["Location"] = 'http://51mole.61.com'..dest,
        })
        res:write("")
    end
end):listen(conf.ressrv_port)

math.randomseed(os.time())

timer.setInterval(flush_time_interval,function()missinglist:flush()end) -- 20秒存一次盘
print("\27[36mRedirect resource server started on \27[1mhttp://localhost:"..conf.ressrv_port.."/\27[0m")
