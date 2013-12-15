cjson = require "cjson"
token = require "token"
common = require "common"

local args = ngx.req.get_uri_args()

if (args.token ~= token) then
	common.json(false, "access deny")
end

os.execute('cp -Rf '..common.nginxPATH..'/conf/ '..common.nginxPATH..'/ocdn_conf_bak/`date +%Y_%m_%d_%H_%M_%S`/')

common.json(true, 'bak command has send')
