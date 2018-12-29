local http = require "http"
local url = require "url"
local fs = require "fs"
local Response = http.ServerResponse
local resp = conf.login_server_address
local resp_404 = "404 Not Found - Project RecMole"

local policy_file = "\
<?xml version=\"1.0\"?><!DOCTYPE cross-domain-policy><cross-domain-policy>\
<allow-access-from domain=\"*\" to-ports=\"*\" /></cross-domain-policy>\000\
"

http.createServer(function(req, res)
    req.uri = url.parse(req.url)
    p("ip access")
    if req.uri.pathname == "/ip.txt" then
        res:writeHead(200, {
            ["Content-Type"] = "text/plain",
            ["Content-Length"] = #resp
        })
        res:write(resp)
    elseif req.uri.pathname == "/crossdomain.xml" then
        res:writeHead(200, {
            ["Content-Type"] = "text/plain",
            ["Content-Length"] = #policy_file
        })
        res:write(policy_file)
    else
        res:writeHead(404, {
            ["Content-Type"] = "text/plain",
            ["Content-Length"] = #resp_404
        })
        res:write(resp_404)
    end
end):listen(conf.loginip_port)

print("\27[36mLogin http server started on \27[1mhttp://localhost:"..conf.loginip_port.."/\27[0m")
