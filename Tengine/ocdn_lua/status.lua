
cjson = require "cjson"
require "token"
require "common"

local args = ngx.req.get_uri_args()

if (args.token ~= token) then
	json(false, "access deny")
end

info = {
	system = false,
	kernel = false,
	memory = {},
	cpu = {},
	load = {},
	network = {},
	storage = {},
	version = version
}

info.system = fileload("/etc/issue", "line")
info.kernel = fileload("/proc/version", "line")

-- cpu info catch
local result = fileload("/proc/cpuinfo", "all")

i , stop, count = 0 , 0, 2
cpuList = { [1] = {start = 0, stop = 0}}
while true do
	start,stop = string.find(result, '[\n][\n]', stop + 1)
	if start == nil then break end

	local prev = count - 1
	if(cpuList[prev]) then
		cpuList[prev].stop = start
	end

	cpuList[count] = {
		start = stop,
		stop = 0
	}
	count = count + 1
end

-- cpu model
cpuType = {}
for key, value  in pairs(cpuList) do
	if(value.stop ~= 0) then
		cpuEle = string.sub(result, value.start, value.stop)
		cpuInfo = {}
		for ele in string.gfind(cpuEle, "[^\n]*[\n]") do
			i,j = string.find(ele, "[^\n]*:")
			if(i) then 
				key = string.sub(ele, i, j-1)
				key = string.gsub(key, "\t", "")
			end
			i,j = string.find(ele, ":[^\n]*")
			if(i) then value = string.sub(ele, i+1, j) else value = "" end
			if(key) then cpuInfo[key] = value end
		end
		if(cpuInfo['core id'] and cpuInfo['model name'] and cpuInfo['physical id']) then
			if(cpuType['cpu'..tonumber(cpuInfo['physical id'])]) then
				table.insert(cpuType['cpu'..tonumber(cpuInfo['physical id'])]['core_id'], tonumber(cpuInfo['core id']))
			else
				cpuType['cpu'..tonumber(cpuInfo['physical id'])] = {
					name = cpuInfo['model name'],
					core_id = {tonumber(cpuInfo['core id'])}
				}
			end
		end
	end
end

info.cpu['info'] = cpuType

local sysinfo = fileload("/usr/local/opencdn/node/sysinfo.txt", "object")

if(sysinfo) then
	for ele in sysinfo:lines() do
		valtab = {}
		for val in string.gmatch(ele, "[^\|]+") do
			table.insert(valtab, val)
		end
		if(valtab[1] == "cpu") then
			info.cpu.status = null
			if(valtab[2]) then info.cpu.status = valtab[2] end
		elseif(valtab[1] == "memory") then
			info.memory.swap = {}
			info.memory.mem = {}
			if(valtab[2]) then info.memory.mem.total = valtab[2] end
			if(valtab[3]) then info.memory.mem.used = valtab[3] end
			if(valtab[4]) then info.memory.mem.per = valtab[4] end
		elseif(valtab[1] == "interface") then
			intr = {info = {}, count={}}
			local name = valtab[2]
			if(valtab[3]) then intr.info.inet = valtab[3] end
			if(valtab[5]) then intr.count["receive-bytes"] = valtab[5] end
			if(valtab[6]) then intr.count["receive-bytes-speed"] = valtab[6] end
			if(valtab[8]) then intr.count["transmit-bytes"] = valtab[8] end
			if(valtab[9]) then intr.count["transmit-bytes-speed"] = valtab[9] end
			info.network[name] = intr
		end
	end	
else

	-- cpuinfo = {}
	-- local stat = fileload("/proc/stat", "all")
	-- for ele in string.gfind(stat, "[^\n]*[\n]") do
	-- 	i,j = string.find(ele, "cpu")
	-- 	if i == nil then break end
	-- 	key = string.sub(ele, i, j)
	-- 	values = {}
	-- 	total = 0
	-- 	for keyele in string.gfind(ele, "[%d]+") do
	-- 		total = total + tonumber(keyele)
	-- 		table.insert(values, tonumber(keyele))
	-- 	end
	-- 	cpuinfo['first'] = {}
	-- 	-- cpuinfo['first'].idle = tonumber(values[4])
	-- 	cpuinfo['first'].idle = tonumber(values[1] + values[2] + values[3])
	-- 	cpuinfo['first'].total = total
	-- 	break
	-- end

	-- -- memory info finish!
	-- local memory = fileload("/proc/meminfo", "object")
	-- meminfo = {}

	-- if (memory) then
	-- 	for ele in memory:lines() do
	-- 		i,j = string.find(ele, "^[%w_]+")
	-- 		if(i) then key = string.sub(ele, i, j) end
	-- 		i,j = string.find(ele, ":%s*([0-9]+)")
	-- 		if(i) then value = tonumber(string.sub(ele, i+1, j)) end
	-- 		if(key and value) then meminfo[key] = value end
	-- 	end
	-- 	info.memory['mem'] = {
	-- 		total = meminfo['MemTotal'],
	-- 		free = meminfo['MemFree'],
	-- 		cached = meminfo['Cached'],
	-- 		buffers = meminfo['Buffers'],
	-- 		used = meminfo['MemTotal'] - meminfo['MemFree'] - meminfo['Cached'] - meminfo['Buffers']
	-- 	}
	-- 	info.memory['swap'] = {
	-- 		total = meminfo['SwapTotal'],
	-- 		free = meminfo['SwapFree'],
	-- 		cached = meminfo['SwapCached'],
	-- 		used = meminfo['SwapTotal'] - meminfo['SwapFree'] - meminfo['SwapCached']
	-- 	}
	-- end

	-- -- cpu load finish!
	-- local load = fileload("/proc/loadavg", "line")

	-- if (load) then
	-- 	local loadName = {"5min", "10min", "15min", "process", "lastpid"}
	-- 	local count = 1
	-- 	for ele in string.gfind(load, "%S+") do
	-- 		if(loadName[count]) then
	-- 			info.load[loadName[count]] = ele
	-- 			count = count + 1
	-- 		end
	-- 	end
	-- 	if(info.load.process) then		--fix process
	-- 		local process = {"processrun", "processtotal"}
	-- 		local count = 1
	-- 		for ele in string.gfind(info.load.process, "%d+") do
	-- 			if(process[count]) then
	-- 				info.load[process[count]] = ele
	-- 				count = count + 1
	-- 			end
	-- 		end
	-- 		info.load.process = nil
	-- 	end
	-- end

	-- -- network finish!
	-- local network = fileload("/proc/net/dev", "object")
	-- local count = 0
	-- for ele in network:lines() do
	-- 	if(count > 1) then
	-- 		local netfield = {[1] = "name", [2] = "receive-bytes", [10] = "transmit-bytes"}
	-- 		local netcount = 1
	-- 		local netarray = {info = {}, count = {}}
	-- 		for netele in string.gfind(ele, "[^\:%s]+") do
	-- 			if(netfield[netcount] and netele) then
	-- 				if(netfield[netcount] ~= "name") then
	-- 					netarray.count[netfield[netcount]] = netele.."byte"
	-- 				else
	-- 					netarray.count[netfield[netcount]] = netele
	-- 				end
	-- 			end
	-- 			netcount = netcount + 1
	-- 		end
	-- 		local name = string.gsub(netarray.count.name, ":", "")
	-- 		netarray.count.name = nil
	-- 		info.network[name] = netarray	
	-- 	end
	-- 	count = count + 1
	-- end

	-- -- network fix
	-- for key, val in pairs(info.network) do
	-- 	local test = io.popen('/sbin/ifconfig '..key..' | grep "inet "')
	-- 	local result = test:read("*all")
	-- 	if(result and string.len(result) > 0) then
	-- 		for ele in string.gfind(result, "%S+%s+[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+") do
	-- 			local i,j = string.find(ele, "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")
	-- 			if (i) then ip = string.sub(ele, i, j) end
	-- 			local i,j = string.find(ele, "[a-z]+")
	-- 			if (i) then name = string.sub(ele, i, j) end
	-- 			info.network[key].info[name] = ip
	-- 		end
	-- 	end
	-- end


	-- local stat = fileload("/proc/stat", "add")
	-- for ele in string.gfind(stat, "[^\n]*[\n]") do
	-- 	i,j = string.find(ele, "cpu")
	-- 	if i == nil then break end
	-- 	key = string.sub(ele, i, j)
	-- 	values = {}
	-- 	total = 0
	-- 	for keyele in string.gfind(ele, "[%d]+") do
	-- 		total = total + tonumber(keyele)
	-- 		table.insert(values, tonumber(keyele))
	-- 	end
	-- 	cpuinfo['second'] = {}
	-- 	cpuinfo['second'].idle = tonumber(values[1] + values[2] + values[3])
	-- 	-- cpuinfo['second'].idle = tonumber(values[4])
	-- 	cpuinfo['second'].total = total
	-- 	break
	-- end

	-- info.cpu.status = 1 - (cpuinfo['second'].idle - cpuinfo['first'].idle) / (cpuinfo['second'].total - cpuinfo['first'].total)

	-- if(info.cpu.status == 0) then info.cpu.status = 0.1 end
end


json(true, info)

