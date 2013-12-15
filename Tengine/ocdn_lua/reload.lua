cjson = require "cjson"
token = require "token"
common = require "common"

local args = ngx.req.get_uri_args()

if (args.token ~= token) then
	common.json(false, "access deny")
end

local cmd = io.popen(common.nginxPATH..'/sbin/nginx -s reload')
common.json(true, "has send")
