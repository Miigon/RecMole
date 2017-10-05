local http = require('http')
local url = require('url')
local fs = require('fs')
local Response = require('http').ServerResponse
local resp = conf.login_server_address
http.createServer(function(req, res)
  req.uri = url.parse(req.url)
  if req.uri.pathname ~= "/ip.txt" then return end
  res:writeHead(200, {
    ["Content-Type"] = "text/plain",
    ["Content-Length"] = #resp
  })
  res:write(resp)
  print("Requested login server ip:",resp)
end):listen(conf.loginip_port)

print("\27[36mLogin http server started on \27[1mhttp://localhost:"..conf.loginip_port.."/\27[0m")
