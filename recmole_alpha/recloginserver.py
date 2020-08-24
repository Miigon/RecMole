import struct
import asyncio
import random
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
            if packet_length < packetHeadLength: # smaller than the smallest possible packet
                continue

            # read the whole packet, except for the first uint(packet length).
            packet_data = await reader.readexactly(packet_length-4)
            packet_head = struct.unpack("!bIIi",packet_data[0:packetHeadLength-4])
            # Packet head: b[version] I[cmdId] I[userId] I[errorId]
            if packet_head[0] != 1 or packet_head[3] != 0: 
                # version is always 1 and errorId is normally 0
                continue
            cmdId = packet_head[1]
            userId = packet_head[2]
            print(f"LOGIN SERVER: userId:{userId!r} cmdId:{cmdId!r} len:{packet_length!r}")
            packet_body_data = packet_data[packetHeadLength-4:packet_length]
            

            ### handle login command
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
                session = self.generateSession()
                flag = 0 # 0-success 1-wrong password 2-wrong captcha
                self.sendPacket(writer,
                    LoginCmd.LOGIN,
                    userId,
                    0,
                    struct.pack("!I 16s I",flag,session.encode("utf-8"),1) # the third field is undocumented, but 1 works.
                    )

            elif cmdId == LoginCmd.GET_GOOD_SERVER_LIST:
                packet_body = struct.unpack("!16s I",packet_body_data)
                # GET_GOOD_SERVER_LIST: 16s[session] I[loginType]
                session = packet_body[0]
                loginType = packet_body[1]
                print(f"* get good server list: id:{userId!r}")
                # TODO: implement friend and vip system
                isVip = 0
                friendCount = 0
                self.sendPacket(writer,
                    LoginCmd.GET_GOOD_SERVER_LIST,
                    userId,
                    0,
                    makeServerListData(self.getServerList(userId)) + struct.pack("!III",self.getMaxServerId(),isVip,friendCount)
                    )

            elif cmdId == LoginCmd.GET_SERVER_LIST:
                packet_body = struct.unpack("!III",packet_body_data)
                # GET_SERVER_LIST: I[startId] I[endId] I[friendCount] { friendCount * I[friend] }
                startId = packet_body[0]
                endId = packet_body[1]
                friendCount = packet_body[2]
                friendIds = struct.unpack(f"!4x 4x 4x {friendCount!s}I",packet_body_data)
                print(f"* get server list: id:{userId!r}, from {startId!r} to {endId!r}, friendCount: {friendCount!r}")
                self.sendPacket(writer,
                    LoginCmd.GET_SERVER_LIST,
                    userId,
                    0,
                    makeServerListData(self.getServerList(userId))
                    )
            
            elif cmdId == LoginCmd.GET_AUTHCODE:
                print(f"* get authcode: id:{userId!r}")
            
            elif cmdId == LoginCmd.CREATE_MOLE:
                print(f"* create mole: id:{userId!r}")

    def getGoodServerList(self,userId):
        return [
            {
                "id": 1,
                "userCount": 0,
                "ip": "127.0.0.1",
                "port": 32410,
                "friends": 0,
            },
            {
                "id": 2,
                "userCount": 10,
                "ip": "127.0.0.1",
                "port": 32410,
                "friends": 0,
            },
            {
                "id": 3,
                "userCount": 20,
                "ip": "127.0.0.1",
                "port": 32410,
                "friends": 0,
            }
        ]

    def getServerList(self,userId):
        return self.getGoodServerList(userId)

    def getMaxServerId(self):
        return 3

    def generateSession(self):
        return hex(random.randint(0x1000000000000000,0xffffffffffffffff))[2:]

    def sendPacket(self,writer,cmdId,userId,errorId,body):
        print(f"send packet with body len: {len(body)!r}")
        length = packetHeadLength + len(body)
        # Packet head: b[version] I[cmdId] I[userId] I[errorId]
        # version field doesn't really matter since client don't check for it
        writer.write(struct.pack("!IbIII",length,1,cmdId,userId,errorId))
        writer.write(body)

    async def serveForever(self):
        async with self.server:
            await self.server.serve_forever()


def makeServerListData(serverList):
    serverDataList = []
    for srv in serverList:
        serverDataList.append(struct.pack(f"!II 16s HI",srv["id"],srv["userCount"],srv["ip"].encode("utf-8"),srv["port"],srv["friends"]))
        # ServerData: I[serverId] I[userCount] 16s[ip] H[port] I[friends]
    serverData = b"".join(serverDataList)
    return struct.pack("!I",len(serverDataList)) + serverData # `*` unpacks the list into arguments.
