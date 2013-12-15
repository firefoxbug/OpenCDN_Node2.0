cjson = require "cjson"
token = require "token"
common = require "common"

local args = ngx.req.get_uri_args()

if (args.token ~= token) then
	commmon.json(false, "access deny")
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


os.execute('echo "'..common.nginxPATH..'/sbin/nginx -s stop" > '..common.ocdnPATH..'/pipe/command.pipe ')
os.execute('echo "'..common.nginxPATH..'/sbin/nginx -s start" > '..common.ocdnPATH..'/pipe/command.pipe ')

--ngx.say('echo "'..common.nginxPATH..'/sbin/nginx -s start" > '..common.ocdnPATH..'/pipe/command.pipe ')

common.json(true, "has send")
