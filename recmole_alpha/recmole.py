import asyncio
from recloginserver import RecLoginServer

print("=== RecMole Alpha ===")
print("Currently resource server hasn't been re-written for alpha version yet.")
print("You have to use the old luvit version of ressrv.")
print("")


async def main():
    loginserver = RecLoginServer()
    await loginserver.bind('localhost', 32402)
    await loginserver.serveForever()

asyncio.run(main())
