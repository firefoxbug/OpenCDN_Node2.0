cjson = require "cjson"
token = require "token"
common = require "common"

local args = ngx.req.get_uri_args()

if (args.token ~= token) then
	common.json(false, "access deny")
end

if not args.domain then
	common.json(false, "domain arg is empty")
end

local domain = args.domain

local checkdomain = string.find(domain, "^[0-9a-zA-Z\.\-]+$")
if not checkdomain then common.json(false, "domain unaccept") end

os.execute("rm -Rf /home/cache/"..domain)

common.json(true, "has send")
