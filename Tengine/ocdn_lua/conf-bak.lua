cjson = require "cjson"
require "token"
require "common"

local args = ngx.req.get_uri_args()

if (args.token ~= token) then
	json(false, "access deny")
end

os.execute('cp -Rf '..nginxPATH..'/conf/ '..nginxPATH..'/ocdn_conf_bak/`date +%Y_%m_%d_%H_%M_%S`/')

json(true, 'bak command has send')