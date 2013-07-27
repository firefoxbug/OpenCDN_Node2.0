cjson = require "cjson"
require "token"
require "common"

local args = ngx.req.get_uri_args()

if (args.token ~= token) then
	json(false, "access deny")
end

local result,msg = conftest()
if(result) then
	json(true, msg)
else
	json(false, msg)
end




