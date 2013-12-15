cjson = require "cjson"
token = require "token"
common = require "common"

local args = ngx.req.get_uri_args()

if (args.token ~= token) then
	common.json(false, "access deny")
end

local result,msg = common.conftest()
if(result) then
	common.json(true, msg)
else
	common.json(false, msg)
end




