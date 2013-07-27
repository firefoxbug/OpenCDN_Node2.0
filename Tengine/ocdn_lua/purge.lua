cjson = require "cjson"
require "token"
require "common"

local args = ngx.req.get_uri_args()

if (args.token ~= token) then
	json(false, "access deny")
end

if not args.domain then
	json(false, "domain arg is empty")
end

domain = args.domain

local checkdomain = string.find(domain, "^[0-9a-zA-Z\.\-]+$")
if not checkdomain then json(false, "domain unaccept") end

os.execute("rm -Rf /home/cache/"..domain)

json(true, "has send")
