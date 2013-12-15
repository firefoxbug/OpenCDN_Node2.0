cjson = require "cjson"
token = require "token"
common = require "common"

ngx.req.read_body()
local args = ngx.req.get_uri_args()
local post = ngx.req.get_post_args()

if (args.token ~= token) then
	common.json(false, "access deny")
end

local min = 10
local domain = 'all'
local time = os.time()

if args.min then min = args.min end
if args.domain then domain = args.domain end
if args.time then time = args.time end

local info = {total = {total_byte = 0, total_count = 0, hit_byte = 0, hit_count = 0}}
local domains = {}
if (domain == 'all') then
	local list = io.popen("ls -1 "..common.ocdnPATH.."/stream/")
	for ele in list:lines() do
		table.insert(domains, ele)
	end
else
	local checkdomain = string.find(domain, "^[0-9a-zA-Z\.\-]+$")
	if not checkdomain then common.json(false, "domain unaccept") end
	table.insert(domains, domain)
end

for key, val in pairs(domains) do
	local file = string.gsub(val, "[\.]", "_")
	file = common.ocdnPATH.."/stream/"..file.."/"
	info[val] = {}
	for i = 0, min * 60, 60 do
		loadpath = file..os.date("%Y_%b_%d_%H_%M", time - i)
		time_key = os.date("%Y-%m-%d_%H:%M", time - i)
		local load = common.fileload(loadpath, "line")
		local data = {total_byte = 0, total_count = 0, hit_byte = 0, hit_count = 0}
		if(load) then
			local names = {"total_byte", "total_count", "hit_byte", "hit_count"}
			local count = 1
			for ele in string.gfind(load, "%d+") do
				if(names[count]) then
					data[names[count]] = ele
					count = count + 1
				end
			end	
		end
		data.time = time_key
		table.insert(info[val], data)
	end
end

common.json(true, info)

