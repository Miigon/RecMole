import struct
import asyncio
from loginprotocol import LoginCmd

policy_file = b"\
<?xml version=\"1.0\"?><!DOCTYPE cross-domain-policy><cross-domain-policy>\
<allow-access-from domain=\"*\" to-ports=\"*\" /></cross-domain-policy>\000\
"
packetHeadLength = 17 # including the length of the first uint storing packet length

class RecLoginServer:
    def __init__(self):
        pass

    async def bind(self,addr,port):
        self.server = await asyncio.start_server(
        self.handle_data, addr, port)
        print(f'Serving on {self.server.sockets[0].getsockname()}')

    async def handle_data(self,reader,writer):
        try:
            await self.loop(reader,writer)
        except asyncio.IncompleteReadError:
            # reaching EOF, usually means socket disconnected. Do nothing.
            pass
        finally:
            writer.close() # close the connection
            

    async def loop(self,reader,writer):
        # Looping for packets
        while True:
            length_data = await reader.readexactly(4)
            
            # Check for policy-file-request
            if length_data == b"<pol":
                if await reader.readuntil(separator=b'\0') == b"icy-file-request/>\0":
                    # Sending policy file
                    writer.write(policy_file)
                    #print("* sent policy file!")
                    writer.close()
                    break

            packet_length = struct.unpack("!I",length_data)[0]
            print(f"expecting bytes:{packet_length!r}")
            if packet_length < packetHeadLength:
                continue

            # read the whole packet, except for the first uint(packet length).
            packet_data = await reader.readexactly(packet_length-4)
            packet_head = struct.unpack("!bIIi",packet_data[0:packetHeadLength-4])
            # Packet head: b[constant 1] I[cmdId] I[userId] i[constant 0]
            if packet_head[0] != 1 or packet_head[3] != 0: 
                ## these two values are used to check if it's a vaild packet
                ## client writes them with 1 and 0 respectively every time.
                continue
            cmdId = packet_head[1]
            userId = packet_head[2]
            print(f"LOGIN SERVER: userId:{userId!r} cmdId:{cmdId!r} len:{packet_length!r}")
            packet_body_data = packet_data[packetHeadLength-4:packet_length]
            if cmdId == LoginCmd.LOGIN:
                packet_body = struct.unpack("!32s III 22s 64s",packet_body_data)
                # CMD_LOGIN: 32s[pwdMD5] I[loginType] I[constant 1] I[constant 0] 22s[authcode] 64s[adMsg]
                if packet_body[2] != 1 or packet_body[3] != 0:
                    continue
                passwordMD5 = packet_body[0]
                loginType = packet_body[1]
                #authCode = packet_body[4]
                adMsg = packet_body[5]
                
                print(f"* Login request: id:{userId!r} pass:{passwordMD5!r} type:{loginType!r}")
            elif cmdId == LoginCmd.GET_GOOD_SERVER_LIST:
                pass
            elif cmdId == LoginCmd.GET_SERVER_LIST:
                pass
            elif cmdId == LoginCmd.GET_AUTHCODE:
                pass
            elif cmdId == LoginCmd.CREATE_MOLE:
                pass

            

    async def serveForever(self):
        async with self.server:
            await self.server.serve_forever()

