nginxPATH = "/usr/local/nginx"
ocdnPATH = "/usr/local/opencdn"
version = 1.06

function json(result, content)
	local json_res = {
		result = false,
		msg = ""
	}
	if(result) then
		json_res.msg = nil
		json_res.data = content
		json_res.result = true
	else
		json_res.msg = content
	end
	json_text = cjson.encode(json_res)
	ngx.print(json_text)
	ngx.exit(ngx.HTTP_OK)
end

function fileload(path, type)
	-- local result
	-- if pcall(function ()
	-- 	local file = io.open(path, "r")
	-- 	if(type == "line") then
	-- 		result = file:read("*line")
	-- 	elseif (type == "object") then
	-- 		result = file
	-- 	else
	-- 		result = file:read("*all")
	-- 	end
	-- end) then
	-- 	return result
	-- else 
	-- 	ngx.log(ngx.ERR, debug.traceback())
	-- 	return false
	-- end
	ok, err = io.open(path, "r")
	if(ok) then
		if(type == "line") then
			result = ok:read("*line")
		elseif (type == "object") then
			result = ok
		else
			result = ok:read("*all")
		end
		return result
	else
		ngx.log(ngx.ERR, err)
		return false
	end
end

function conftest()
	local test = io.popen(nginxPATH..'/sbin/nginx -t 2>&1')
	local result = test:read("*all")
	local status = false
	local info = {}
	for ele in string.gfind(result, "[^\n]*[\n]") do
		i,j = string.find(ele, "successful")
		if(i) then status = true end

		local etype,eshow,efile,eline = string.match(ele,"^nginx:%s+(\[[a-z]+\])%s+(.+)%s+in%s+(%S+)\:(%d+)")
		if(etype and eshow and efile and eline) then
			nowerror = {
				error = string.sub(etype, 2, -2),
				msg = eshow,
				file = efile,
				line = eline
			}
			table.insert(info, nowerror)	
		end
	end

	return status, info
end

function tree(path, all)
	local all = all or false
	local ls = io.popen('ls -l '..path)
	local files = {}
	for ele in ls:lines() do
		local fs = {"privilege", "total", "user", "group", "size", "month", "day", "time", "name"}
		local count = 1
		local file = {}
		for fsele in string.gfind(ele, "%S+") do
			if(fs[count]) then
				file[fs[count]] = fsele
				count = count + 1
			end
		end
		if(string.sub(file.privilege, 0, 1) == "d") then
			file.type = "dict"
			if(all and file.name) then
				file.list = tree(path.."/"..file.name, true)
			end
		else
			file.type = "file"
		end
		if(file.name) then files[file.name] = file end
	end
	return files
end

-- a,b = conftest()
-- ngx.say(a)
-- ngx.say(b)
