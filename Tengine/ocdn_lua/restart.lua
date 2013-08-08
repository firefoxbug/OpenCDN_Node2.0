cjson = require "cjson"
require "token"
require "common"

local args = ngx.req.get_uri_args()

if (args.token ~= token) then
	json(false, "access deny")
end

-- local ok = io.open("../logs/nginx.pid", "r")
-- local result = ok:read("*all")
-- ngx.say(result)

-- local cmd = io.popen('./nginx -s stop&; ./nginx -s start&')
-- local cmd = os.execute('killall nginx; ./nginx -s start&')

-- local cmd = os.execute('nohup sh ./restart.sh &')

-- local ok, err = io.open("/tmp/no-such-file", "r")
-- local ok = io.open("/proc/cpuinfo23", "r")
-- ngx.say(ok)
-- if not ok then ngx.print(err) end

-- json(true, "has send")

os.execute(nginxPATH.."/sbin/nginx -s stop")
os.execute('echo "'..nginxPATH..'/sbin/nginx -s start" > '..ocdnPATH..'/pipe/command.pipe ')

json(true, "has send")