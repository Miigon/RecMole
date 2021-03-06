local http = require "http"
local url = require "url"
local fs = require "fs"
local Response = http.ServerResponse
local root = conf.res_dir
local proxy_root = conf.res_proxy_dir
local mimes = require "./mimes"
mimes.default = "application/octet-stream"

-- Redirection
local PASSTHROUGH = 0   -- 发送官方原版资源文件
local PROXY = 1         -- 发送修改过的资源文件
local REDIRECT = 2      -- 301 重定向到其他服务器
local INVISIBLE = 3     -- 404 不存在
local DEFAULT = PASSTHROUGH
local proxy_rules = 
{
    ["/"] = "/index.html",
    ["/index.html"] = PROXY,
    ["/config/Server.xml"] = conf.res_connect_official_server and DEFAULT or PROXY,
    ["/dll/ClientCommonDLL.swf"] = conf.res_bypass_encrypt and PROXY or DEFAULT,
    ["/resource/login/Advertisement.swf"] = INVISIBLE,
}

local INVISIBLE_REASON = "the file is defined as invisible by proxy_rules"

function getType(path)
    return mimes[path:lower():match("[^.]*$")] or mimes.default
end

function Response:notFound(path,reason)
    local req
    local resp = self
    local data = ""
    -- 尝试从官网获取
    print("\27[32mFetching from official: "..path,"\27[0m")
    req = http.request(conf.res_official_address..path, function(res)
        res:on('data', function (chunk)
            data = data .. chunk
        end)
        res:on('end',function()
            print("Status code:",res.statusCode)
            -- 官网上存在文件
            if(res.statusCode == 200) then
                -- 创建目录
                local curr = root
                local t = {}
                for w in string.gmatch(path,"([^'/']+)") do
                    table.insert(t,w)
                end
                for i=1,#t-1 do
                    curr = curr .."/".. t[i]
                    if fs.existsSync(curr) == false then
                        print("\27[33mNew directory:",curr,"\27[0m")
                        fs.mkdirSync(curr)
                    end
                end
                -- 保存官网文件
                fs.writeFile(root .. path,data)
                resp:writeHead(200, {
                    ["Content-Type"] = getType(path),
                    ["Content-Length"] = #data
                })
                resp:write(data)
            else
                resp:writeHead(404, {
                    ["Content-Type"] = "text/plain",
                    ["Content-Length"] = #reason
                })
                resp:write(reason)
            end
        end)
    end)
    req:done()
end

function Response:error(reason)
    self:writeHead(500, {
        ["Content-Type"] = "text/plain",
        ["Content-Length"] = #reason
    })
    self:write(reason)
end

local function resolvePathByProxyRules(dest)
    local proxy_rule = proxy_rules[dest] or DEFAULT
    local rootpath = root
    local code = 200
    if proxy_rule == PROXY then
        rootpath = proxy_root
    elseif proxy_rule == PASSTHROUGH then
        -- Do nothing
    elseif proxy_rule == REDIRECT then
        code = 301
    elseif proxy_rule == INVISIBLE then
        code = 404
    elseif type(proxy_rule) == "string" then
        return resolvePathByProxyRules(proxy_rule)
    end
    return (rootpath .. dest),code
end

http.createServer(function(req, res)
    req.uri = url.parse(req.url)
    local dest = req.uri.pathname
    print("\27[1;37mAccess",dest,"\27[0m")
    
    local path,code = resolvePathByProxyRules(dest)
    if code == 301 then
        -- TODO: REDIRECT
    elseif code == 404 then
        res:writeHead(404, {
            ["Content-Type"] = "text/plain",
            ["Content-Length"] = #INVISIBLE_REASON
        })
        res:write(INVISIBLE_REASON)
        return
    else
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
    
            res:writeHead(200, {
                ["Content-Type"] = getType(path),
                ["Content-Length"] = stat.size
            })
    
            fs.createReadStream(path):pipe(res)
        end)
    end
end):listen(conf.ressrv_port)

print("\27[36mResource server started on \27[1mhttp://localhost:"..conf.ressrv_port.."/\27[0m")