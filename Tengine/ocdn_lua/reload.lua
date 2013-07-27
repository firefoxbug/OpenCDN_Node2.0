cjson = require "cjson"
require "token"
require "common"

local args = ngx.req.get_uri_args()

if (args.token ~= token) then
	json(false, "access deny")
end

local cmd = io.popen(nginxPATH..'/sbin/nginx -s reload')
json(true, "has send")