cjson = require "cjson"
require "token"
require "common"

local args = ngx.req.get_uri_args()

if (args.token ~= token) then
	json(false, "access deny")
end

tree = tree(nginxPATH.."/conf", true)
json(true, tree)


