cjson = require "cjson"
token = require "token"
common = require "common"

ngx.req.read_body()
local args = ngx.req.get_uri_args()
local post = ngx.req.get_post_args()

if (args.token ~= token) then
	common.json(false, "access deny")
end

if not args.file then
	common.json(false, "file arg is empty")
end

local reload = false
if args.reload == "yes" then reload = true end

--check file name
local tmpfile = string.gsub(args.file, "/", " ")
for ele in string.gfind(tmpfile, "%S+") do
	local checkdir = string.find(ele, "^[0-9a-zA-Z_\-]+$")
	local checkfile = string.find(ele, "^[0-9a-zA-Z_\-]*[\.][0-9a-zA-Z_\-]+$")
	if not checkdir and not checkfile then
		common.json(false, "unaccess file name!")
	end
end

local file,err = io.open(common.nginxPATH..'/conf/'..args.file, "w")
if not file then
	common.json(false, err)
end

if not post.body then
	common.json(false, "the file body is empty")
end

file:write(post.body)
file:close()

if reload then
	io.popen(common.nginxPATH..'/sbin/nginx -s reload')
end

common.json(true, 'has wrote')





