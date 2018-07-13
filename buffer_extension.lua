local buffer = require "buffer"
buffer.Buffer.write = function(buf,pos,str,len)
    local getbyte = string.byte
    local i = 0
    for c in str:gmatch"." do
        if i < len then
            buf:writeUInt8(pos+i,getbyte(c))
        else
            return
        end
        i = i + 1
    end
    for j = i,len-1 do
        buf:writeUInt8(pos+j,0)
    end
end

buffer.Buffer.wuint = buffer.Buffer.writeUInt32BE
buffer.Buffer.wbyte = buffer.Buffer.writeUInt8
buffer.Buffer.wushort = buffer.Buffer.writeUInt16BE

buffer.Buffer.ruint = buffer.Buffer.readUInt32BE
buffer.Buffer.rint = buffer.Buffer.readInt32BE
buffer.Buffer.rbyte = buffer.Buffer.readUInt8