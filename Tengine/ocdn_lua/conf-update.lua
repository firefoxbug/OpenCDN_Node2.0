cjson = require "cjson"
require "token"
require "common"

ngx.req.read_body()
local args = ngx.req.get_uri_args()
local post = ngx.req.get_post_args()

if (args.token ~= token) then
	json(false, "access deny")
end

if not args.file then
	json(false, "file arg is empty")
end

reload = false
if args.reload == "yes" then reload = true end

--check file name
local tmpfile = string.gsub(args.file, "/", " ")
for ele in string.gfind(tmpfile, "%S+") do
	local checkdir = string.find(ele, "^[0-9a-zA-Z_\-]+$")
	local checkfile = string.find(ele, "^[0-9a-zA-Z_\-]*[\.][0-9a-zA-Z_\-]+$")
	if not checkdir and not checkfile then
		json(false, "unaccess file name!")
	end
end

local file,err = io.open(nginxPATH..'/conf/'..args.file, "w")
if not file then
	json(false, err)
end

if not post.body then
	json(false, "the file body is empty")
end

file:write(post.body)
file:close()

if reload then
	io.popen(nginxPATH..'/sbin/nginx -s reload')
end

json(true, 'has wrote')





