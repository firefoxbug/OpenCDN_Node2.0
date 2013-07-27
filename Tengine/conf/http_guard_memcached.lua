local cookie = ngx.var.cookie_httpguard or 100000000;
local ip = ngx.var.remote_addr;
local uri = ngx.var.request_uri;
local filename = ngx.var.request_filename;

--连接memcached
local memcached = require "resty.memcached"
local http_guard_mem, err = memcached:new()
if not http_guard_mem then
	ngx.log(ngx.ERR,"failed to instantiate memc: ", err)
	return
end
http_guard_mem:set_timeout(1000) -- 1 sec
local ok, err = http_guard_mem:connect(memcached_server, memcached_port)
if not ok then
	ngx.log(ngx.ERR,"failed to connect: ", err)
	return
end

--请求限速
if cookie_enable == 1 then
	--定义cookie相关key
	local ip_cookie = ngx.md5(table.concat({ip,cookie}));
	local ip_cookie_durl = ngx.md5(table.concat({ip,cookie,"durl"}));
	local ip_cookie_surl = ngx.md5(table.concat({ip,cookie,url}));
	local ip_cookie_aurl = ngx.md5(table.concat({ip,cookie,"aurl"}));
	--计算ip与cookie的md5
	local baduser, _ = http_guard_mem:get(ip_cookie)
	--判断此用户是否在黑名单
	if baduser then
		ngx.exit(444);
	else
		--当url请求的是php文件时
		if ngx.re.match(filename,".*\\.php$","i") then
			local durl = http_guard_mem:get(ip_cookie_durl);
			--判断字典是否存在
			if durl then
				--判断此用户总访问数是否超过限制
				if tonumber(durl) > d_url_max then
					--加入黑名单
					http_guard_mem:set(ip_cookie,0,ban_time);
					ngx.log(ngx.ERR,"http-guard: "..ip.." visit dynamic urls "..durl.." times,exceed "..d_url_max.." limit ")
					--断开连接
					ngx.exit(444);
				else
					--该用户访问此url次数加1
					http_guard_mem:incr(ip_cookie_durl,1);
				end	
			else
				--添加记录进词典
				http_guard_mem:set(ip_cookie_durl,1,10);
			end	
		else
			local surl = http_guard_mem:get(ip_cookie_surl);
			--判断s_url字典是否存在
			if surl then
				--判断此用户访问单个url是否超过限制
				if tonumber(surl) > s_url_max then
					--加入黑名单
					http_guard_mem:set(ip_cookie,0,ban_time);
					ngx.log(ngx.ERR,"http-guard: "..ip.." visit single url "..surl.." times,exceed "..s_url_max.." limit ")
					--断开连接
					ngx.exit(444);
				else
					--该用户访问此url次数加1
					http_guard_mem:incr(ip_cookie_surl,1);
				end
			else
				--添加记录进s_url词典
				http_guard_mem:set(ip_cookie_surl,1,10);
			end
			--判断a_url字典是否存在
			local aurl = http_guard_mem:get(ip_cookie_aurl);
			if aurl then
				--判断此用户总访问数是否超过限制
				if tonumber(aurl) > a_url_max then
					--加入黑名单
					http_guard_mem:set(ip_cookie,0,ban_time);
					ngx.log(ngx.ERR,"http-guard: "..ip.." visit total urls "..aurl.." times,exceed "..a_url_max.." limit ")
					--断开连接
					ngx.exit(444);
				else
					--该用户访问此url次数加1
					http_guard_mem:incr(ip_cookie_aurl,1);
				end	
			else
				--添加记录进a_url词典
				http_guard_mem:set(ip_cookie_aurl,1,10);
			end
		end	
	end
else
	--分别定义用于记录动态,静态,所有url的key
	local ip_durl = ngx.md5(table.concat({ip,"durl"}));
	local ip_surl = ngx.md5(table.concat({ip,uri}));
	local ip_aurl = ngx.md5(table.concat({ip,"aurl"}));
	local baduser,_=http_guard_mem:get(ip)
	--判断此用户是否在黑名单
	if baduser then
		ngx.exit(444);
	else
		--当请求的是php文件时
		if ngx.re.match(filename,".*\\.php$","i") then
			local durl = http_guard_mem:get(ip_durl);
			--判断a_url字典是否存在
			if durl then
				--判断此用户总访问数是否超过限制
				if tonumber(durl) > d_url_max then
					--加入黑名单
					http_guard_mem:set(ip,0,ban_time);
					ngx.log(ngx.ERR,"http-guard: "..ip.." visit dynamic urls "..durl.." times,exceed "..d_url_max.." limit ")
					--断开连接
					ngx.exit(444);
				else
					--该用户访问此url次数加1
					http_guard_mem:incr(ip_durl,1);
				end	
			else
				--添加记录进词典
				http_guard_mem:set(ip_durl,1,10);
			end	
		else
			--计算ip与cookie,uri的md5,用于限制单个url请求速度
			local surl = http_guard_mem:get(ip_surl);
			local aurl = http_guard_mem:get(ip_aurl);
			--判断s_url字典是否存在			
			if surl then
				--判断此用户访问单个url是否超过限制
				if tonumber(surl) > s_url_max then
					--加入黑名单
					http_guard_mem:set(ip,0,ban_time);
					ngx.log(ngx.ERR,"http-guard: "..ip.." visit single url "..surl.." times,exceed "..s_url_max.." limit ")
					--断开连接
					ngx.exit(444);
				else
					--该用户访问此url次数加1
					local ok, err = http_guard_mem:incr(ip_surl,1);
					if not ok then
						ngx.log(ngx.ERR,"failed to incr dog: ", err)
						return
					end	
				end
			else
				--添加记录进s_url词典
				local ok, err = http_guard_mem:set(ip_surl,1,10);
				if not ok then
					ngx.log(ngx.ERR,"failed to set dog: ", err)
					return
				end				
				
			end
			--判断a_url字典是否存在
			if aurl then
				--判断此用户总访问数是否超过限制
				if tonumber(aurl) > a_url_max then
					--加入黑名单
					http_guard_mem:set(ip,0,ban_time);
					ngx.log(ngx.ERR,"http-guard: "..ip.." visit total urls "..aurl.." times,exceed "..a_url_max.." limit ")
					--断开连接
					ngx.exit(444);
				else
					--该用户访问此url次数加1
					http_guard_mem:incr(ip_aurl,1);
				end	
			else
				--添加记录进a_url词典
				local ok, err = http_guard_mem:set(ip_aurl,1,10);
				if not ok then
					ngx.log(ngx.ERR,"failed to set dog: ", err)
					return
				end					
			end
		end	
	end
end

--只作用在php文件
if ngx.re.match(filename,".*\\.php$","i") then
	--请求过滤
	local url = ngx.unescape_uri(uri)
	--是否开启防sql注入	
	if sql_filter and ngx.re.match(url,sql_filter,"i") then
		ngx.log(ngx.ERR,"http-guard: "..ip.." sql inject")
		ngx.exit(444);
	end		
	if (ngx.req.get_method()=="GET") then	
		--js跳转验证
		if jscc==1 then
			local ip_js = ngx.md5(table.concat({ip,"js"}));
			local jspara,flags = http_guard_mem:get(ip_js);
			local args = ngx.req.get_uri_args();
			if jspara then
				if flags == "0" then
					local p_jskey=''
					if args["jskey"] and type(args["jskey"])=='table' then
							p_jskey=args["jskey"][table.getn(args["jskey"])];
					else
							p_jskey=args["jskey"];
					end
					if p_jskey and p_jskey==tostring(jspara) then
						http_guard_mem:set(ip_js,jspara,white_time,1);
					else
						local url=''
						if ngx.var.args then
							url=table.concat({ngx.var.scheme,"://",ngx.var.host,uri,"&jskey=",jspara});
						else
							url=table.concat({ngx.var.scheme,"://",ngx.var.host,uri,"?jskey=",jspara});
						end
						local jscode=table.concat({"<script>window.location.href='",url,"';</script>"});
						ngx.header.content_type = "text/html"
						ngx.print(jscode)
						ngx.exit(200)
					end
				end
			else
				math.randomseed( os.time() );
				local random=math.random(100000,999999)
				http_guard_mem:set(ip_js,random,60)
				local url=''
				if ngx.var.args then
					url=table.concat({ngx.var.scheme,"://",ngx.var.host,uri,"&jskey=",random});
				else
					url=table.concat({ngx.var.scheme,"://",ngx.var.host,uri,"?jskey=",random});
				end
				local jscode=table.concat({"<script>window.location.href='",url,"';</script>"});
				ngx.header.content_type = "text/html"
				ngx.print(jscode)
				ngx.exit(200)
			end
		end
		--是否开启防xss攻击
		if filte_xss and ngx.re.match(url,filte_xss,"i") then
			ngx.log(ngx.ERR,"http-guard: "..ip.." xss ")
			ngx.exit(444)
		end
		--是否开启禁止某些目录解析php
		if disabled_php_dir and ngx.re.match(url,disabled_php_dir,"i") then
			ngx.exit(444)
		end	
			
	elseif (ngx.req.get_method()=="POST") then
		ngx.req.read_body()
		--是否开启防止php等文件上传
		if filte_file_type and ngx.req.get_body_data() and ngx.re.match(ngx.req.get_body_data(),"Content-Disposition: form-data;.*filename=\".*\\."..filte_file_type.."\"","isjo") then
			ngx.log(ngx.ERR,"http-guard: "..ip.." upload php shell "..ngx.req.get_body_data())
			ngx.exit(444)
		end	
	end
end
--关闭memcached
local ok, err = http_guard_mem:set_keepalive(0, 100)
if not ok then
	ngx.log(ngx.ERR,"cannot set keepalive: ", err)
	return
end