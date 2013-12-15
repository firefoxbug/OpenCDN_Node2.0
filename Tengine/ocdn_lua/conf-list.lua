cjson = require "cjson"
token = require "token"
common = require "common"

local args = ngx.req.get_uri_args()

if (args.token ~= token) then
	common.json(false, "access deny")
end

local tree = common.tree(common.nginxPATH.."/conf", true)
common.json(true, tree)


