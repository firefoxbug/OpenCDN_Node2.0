cjson = require "cjson"
require "token"
require "common"

ngx.req.read_body()
local args = ngx.req.get_uri_args()
local post = ngx.req.get_post_args()

if (args.token ~= token) then
	json(false, "access deny")
end

local conf = io.popen(nginxPATH..'/sbin/nginx -d 2>&1')
local result = conf:read("*all")

reVal = {
	file = {},
	domain = {}
}
start,stop = string.find(result, '# contents of file "*"', 1000)

i , stop, count = 0 , 0, 1
confList = {}
domainList = {}
while true do
    start,stop = string.find(result, '# contents of file \"%S+\"', stop + 1)
    if start == nil then break end

	local prev = count - 1
	if(confList[prev]) then
		confList[prev].stop = start
	end

	confList[count] = {
		file = string.sub(result, start + 20, stop - 1),
		start = stop,
		stop = 0
	}
	count = count + 1
end

reVal.file = {}
for key, value  in pairs(confList) do
	if(value.stop ~= 0) then
		confFile = string.sub(result, value.start, value.stop)
	else
		confFile = string.sub(result, value.start)
	end
	confFile = string.gsub(confFile, "#[^\n]+", "")
	domainConf = {}
	for ele in string.gfind(confFile, "server_name%s+[^\n]+") do
		ele = string.gsub(ele, "server_name", "")
		for doele in string.gfind(ele, "[a-zA-Z\-\.]+") do
			table.insert(domainConf, doele)
			reVal.domain[doele] = value.file
		end
	end
	if(table.getn(domainConf) > 0) then
		reVal.file[value.file] = domainConf
	end
end 

json(true, reVal)
