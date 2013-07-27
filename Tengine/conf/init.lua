--------------全局设置-----------------
http_guard = ngx.shared.http_guard; --声明一个字典
ban_time = 600; --黑名单时间,单位:秒.
cookie_enable = 0;--cookie标记开关,用来解决多用户共享ip上网误判的问题.0为关闭,1为开启.
cookie_name = "httpguard"; --如果怀疑攻击者利用cookie跳过限制,可以修改此cookie_name进行防伪

-----------静态资源变量设置--------------

s_url_max = 50; --单个url 10秒内允许最大访问次数
a_url_max = 100; --10秒内允许的最大总访问次数

------------动态网页变量设置---------------

d_url_max = 50; --10秒内允许的最大总访问次数
jscc = 0;       --js防cc开关,0为关闭,1为开启. 
white_time = 600; -- js跳转验证后白名单的时间.
sql_filter = ".*[; ]?((or)|(insert)|(sleep)|(select)|(union)|(update)|(delete)|(replace)|(create)|(drop)|(alter)|(grant)|(load)|(show)|(exec))[\\s(]" --sql防注入规则,注释则不启用
filte_file_type = "(php|jsp)";--禁止上传的文件后缀,注释则不过滤
filte_xss = "(<iframe|<script|<body|<img|javascript)";--过滤xss代码,注释则不过滤
disabled_php_dir = "(.*/(attachments|js|upimg|images|css|uploadfiles|html|uploads|templets|static|template|data|inc|forumdata|upload|includes|cache|avatar)/\\w+\\.(php|jsp))"

----------使用memcached时用到---------------

--memcached_server="127.0.0.1";
--memcached_port=11211;