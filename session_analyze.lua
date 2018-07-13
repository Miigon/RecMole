-- this program is part of `The RecMole Project`
-- source code published under GNU GPLv3
-- information above should not be deleted
require "./buffer_extension"
local buffer = require "buffer"
local SRV = 1;local CLI = 2
local MAGIC_NUMBER = 1;local TIMESTAMP = 2;local PACKET_DATA = 3

local path = args[2]
local f = io.open(path,"rb")
local str = f:read("*a")
local data = {}
local item
function magiclines(s)
    if s:sub(-1)~="\n" then s=s.."\n" end
    return s:gmatch("(.-)\n")
end

local searching_for = MAGIC_NUMBER 
for l in magiclines(str) do
    if searching_for == MAGIC_NUMBER and l:sub(1,5) == "\xDE\xAD\x12\x45\x00" then
        item = {}
        data[#data+1] = item
        local typ = l:sub(6,8)
        if typ == "SRV" then
            item.type = SRV
        elseif typ == "CLI" then
            item.type = CLI
        else
            print("ERROR TYPE INDICATOR:".. typ)
        end
        searching_for = TIMESTAMP
    elseif searching_for == TIMESTAMP then
        item.timestamp = tonumber(l)
        searching_for = PACKET_DATA
    elseif searching_for == PACKET_DATA then
        if l == "\xDE\xAD\xBE\xEF\x12\x45\x00" then
            searching_for = MAGIC_NUMBER
        else
            item.data = (item.data or "") .. l
        end
    end
end
str = ""

function parse(item)
    local buf = buffer.Buffer:new(item.data)
    local length = buf:ruint(1)
    if length < 17 then return end
    --if buf:readInt8(5) ~= 65 then return end -- Version，65  --Problematic
    local cmdid = buf:ruint(6)
    local userid = buf:ruint(10)
    --print ("收到包 " .. cmdid)
    if buf:ruint(14) ~= 0 then return end -- Result，未知
    item.cmdid = cmdid
    item.length = length or #item.data
    item.userid = userid
end

for i = 1,#data do
    local item = data[i]
    parse(item)
end

print (#data.." packets loaded!")

-- User interface
local cmdlist = require "./cmdlist"
local readline = require "readline"
local Editor = readline.Editor
local History = readline.History
local prettyPrint = require "pretty-print"
local prompt = "> "
local ESC = "\27"
local CSI = ESC .. "["
local RED = CSI.."31m"
local BOLD = CSI.."1m"
local GREEN = CSI.."32m"
local CLEAR = CSI.."0m"
local function CTL_CURSOR_POS(n,m) return(CSI..n..";"..m.."H") end
local function COLUMN(n) return(CSI..n.."G") end
local history = History.new()
if historyLines then
  history:load(historyLines)
end
local editor = Editor.new({
  stdin = prettyPrint.stdin,
  stdout = prettyPrint.stdout,
  history = history
})

function string.split(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter=='') then return false end
    local pos,arr = 0, {}
    for st,sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

local fmt = COLUMN(1).."%s"..COLUMN(8).."%s"..COLUMN(20).."%s"..COLUMN(31).."%s"..COLUMN(40).."%s"..COLUMN(49).."%s"
local function generateLine(...)
    return string.format(fmt,...)
end
local function range_limit(v)
    return math.min(math.max(v,1),#data)
end
local function type_string(type)
    return type == SRV and GREEN.."-> CLI"..CLEAR or RED.."SRV <-"..CLEAR
end
local selected = 1
local buffer_index = 0
local buf

local function check_buffer()
    if buffer_index ~= selected then
        buf = buffer.Buffer:new(data[selected].data:sub(18,-1))
        buffer_index = selected
    end
end

local function select(index)
    selected = index
    print("selected #"..index)
end

local function makeTableHead()
    print(BOLD..generateLine("#","timestamp","direction","cmd","bodylen","description")..CLEAR)
end

local function makeTableItem(i)
    local item = data[i]
    local desc = cmdlist[item.cmdid] and cmdlist[item.cmdid].note or "-"
    item.length = item.length or #item.data
    local bodylen = item.length == #item.data and tostring(item.length-17) or (tostring(item.length-17).."/"..tostring(#item.data-17))
    print(generateLine(i,item.timestamp,type_string(item.type),item.cmdid,bodylen,desc))
end

local placeholderCmd = {class="-",action="-",note="-"}
local last = 1
local lastR2 = 20
local function processLine(line)
    local cmd = line:sub(1,1)
    if cmd == "d" then
        local range = line:sub(2,-1):split("-")
        local R1,R2
        if #range ~= 2 then
            R1 = last
            R2 = lastR2
            if range[1] == "d" then R1 = R1 + 20;R2 = R2 + 20; end
        else
            R1 = tonumber(range[1]) or 1
            R2 = tonumber(range[2]) or R1 + 20
        end
        R1 = range_limit(R1)
        R2 = range_limit(R2)
        makeTableHead()
        for i = R1,R2 do
            makeTableItem(i)
        end
        print("displaying "..R1.." to "..R2)
        last = R1
        lastR2 = R2
    elseif cmd == "p" then
        local index = tonumber(line:sub(2,-1)) or selected
        local item = data[index]
        selected = index
        print(BOLD.."Packet info #"..index..CLEAR)
        print("timestamp  ",item.timestamp)
        print("direction  ",type_string(item.type))
        print("cmd        ",item.cmdid)
        print("bodylen    ",#item.data-17)
        local cmdinfo = cmdlist[item.cmdid] or placeholderCmd
        print("class      ",cmdinfo.class)
        print("action     ",cmdinfo.action)
        print("description",cmdinfo.note)
        select(index)
    elseif cmd == "s" then --select
        local index = tonumber(line:sub(2,-1))
        select(index)
    elseif cmd == "f" then --find
        local tofind = tonumber(line:sub(2,-1))
        local cnt = 0
        if not tofind then print "Invaild cmdid!";return end
        makeTableHead()
        for i=1,#data do
            if data[i].cmdid == tofind then
                makeTableItem(i)
                cnt = cnt + 1
            end
        end
        print (cnt .. " results was found.")
    elseif cmd == "q" then
        os.exit()
    elseif cmd == "r" then --read
        check_buffer()
        local item = data[selected]
        local type = line:sub(2,2)
        if type == "a" then --byteArray
            local arg = line:sub(3,-1):split(",")
            local pos,len
            if #arg ~= 2 then
                print "Invaild statement."
                return
            else
                pos = tonumber(arg[1])
                len = tonumber(arg[2])
                if not pos or not len then print "Invaild position or length." return end
                local maximium = #item.data - 17
                if pos < 0 or len < 0 or pos > maximium or pos+len-1 > maximium then
                    print ("Position or length out of bound! Maximium: " .. maximium)
                    return
                end
                local str = buf:toString(pos,pos+len-1)
                print("As data:")
                p(str)
                print("As string:")
                print(str) -- TODO:Invisible charactor filter
            end
        else
            local pos = tonumber(line:sub(3,-1))
            if type == "u" then --uint
                p(buf:ruint(pos))
            elseif type == "i" then --int
                p(buf:rint(pos))
            elseif type == "s" then --ushort
                p(buf:readUInt16BE(pos))
            elseif type == "b" then --byte
                p(buf:rbyte(pos))
            end
        end

    end
end

local function onLine(err, line)
    assert(not err, err)
    coroutine.wrap(function ()
      if line then
        local ret,err = pcall(function()processLine(line)end)
        if not ret then print(err) end
        editor:readLine(prompt, onLine)
      end
    end)()
end

select(1)
editor:readLine(prompt, onLine)

--CTL_ERASE_DISPLAY()
--CTL_CURSOR_POS(1,1)
--print"HLWORLD"
