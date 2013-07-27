--获取cookie httpguard的值
local cookie = ngx.var.cookie_httpguard;

--当httpguard的值不存在,且cookie_enable为1开启时,向客户端发送cookie
if not cookie and cookie_enable == 1 then
	math.randomseed( os.time() );
    local random=math.random(100000000,999999999);
	ngx.header['Set-Cookie'] = cookie_name.."="..random.."; path=/"
end	