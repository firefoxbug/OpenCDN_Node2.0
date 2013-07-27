cjson = require "cjson"
require "token"
require "common"

local args = ngx.req.get_uri_args()

if (args.token ~= token) then
	json(false, "access deny")
end

if not args.file then
	json(false, "file arg is empty")
end

--check file name
local tmpfile = string.gsub(args.file, "/", " ")
for ele in string.gfind(tmpfile, "%S+") do
	local checkdir = string.find(ele, "^[0-9a-zA-Z_\-]+$")
	local checkfile = string.find(ele, "^[0-9a-zA-Z_\-]*[\.][0-9a-zA-Z_\-]+$")
	if not checkdir and not checkfile then
		json(false, "unaccess file name!")
	end
end

local file,err = io.open(nginxPATH..'/conf/'..args.file, "r")
if not file then
	json(false, err)
end

local result = file:read("*all")
json(true, result)



