local http = require "http"
local url = require "url"
local fs = require "fs"
local Response = http.ServerResponse
local root = conf.res_dir
local mimes = require "./mimes"
mimes.default = "application/octet-stream"

function getType(path)
    return mimes[path:lower():match("[^.]*$")] or mimes.default
end

function Response:notFound(path,reason)
    local req
    local resp = self
    local data = ""
    -- 尝试从官网获取
    print("\27[32mFetching from official: "..path,"\27[0m")
    req = http.request('http://mole.61.com/'..path, function(res)
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

http.createServer(function(req, res)
    req.uri = url.parse(req.url)
    local dest = req.uri.pathname
    if dest == "/config/Server.xml" and conf.res_official_address then
        dest = "/config/Serveroffi.xml"
    end
    if dest == "/dll/ClientCommonDLL.swf" and not conf.res_bypass_encrypt then
        dest = "/dll/ClientCommonDLLoffi.swf"
    end
    local path = root .. dest
    
    print("\27[1;37mAccess",dest,"\27[0m")
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
end):listen(conf.ressrv_port)

print("\27[36mResource server started on \27[1mhttp://localhost:"..conf.ressrv_port.."/\27[0m")