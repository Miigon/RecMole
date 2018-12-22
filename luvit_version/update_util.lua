local http = require "http"
local url = require "url"
local fs = require "fs"
local root = "../res"
local timer = require "timer"

local thread = 0;
local max_thread = 7;

function notFound(path,reason)
    local req
    local resp = self
    local data = ""
    -- 尝试从官网获取
    print("\27[32mFetching from official: "..path,"\27[0m")
    req = http.request('http://51mole.61.com/'..path, function(res)
        --local length = res:getHeader("Content-Length")
        --print("  length:",length)
        res:on('data', function (chunk)
            data = data .. chunk
        end)
        res:on('end',function()
            print("  status code:",res.statusCode)
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
                        print("\27[33m  New directory:",curr,"\27[0m")
                        fs.mkdirSync(curr)
                    end
                end
                -- 保存官网文件
                fs.writeFile(root .. path,data)
            end
            thread = thread - 1
        end)
    end)
    req:done()
    timer.setInterval(10000,function()req:destroy();thread = thread - 1;end)
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
local iter = missinglist:lines();

function actuate()
    if(thread >= max_thread) then return end
    for line in iter do
        ln = ln + 1
        duplist[line] = true
        print("*",line)
        local path = root .. line
        fs.stat(path, function (err, stat)
            if err then
                if err.code == "ENOENT" then
                    return notFound(line,err.message .. "\n")
                elseif err:sub(1,6) == "ENOENT" then
                    return notFound(line,err .. "\n")
                else
                    thread = thread - 1
                    p(err)
                    return
                end
            end
            if stat.type ~= "file" then
                thread = thread - 1
                return p("  requested url is not a file")
            end
            thread = thread - 1
            actuate()
        end)
        thread = thread + 1
        if(thread >= max_thread) then return end
    end
end

actuate()
timer.setInterval(1000,actuate)