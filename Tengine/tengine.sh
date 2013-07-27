#!/bin/bash

# install tengine 1.4.6

# author : firefoxbug
# E-Mail : wanghuafire@gmail.com
# Blog   : www.firefoxbug.net


## Check if user is root
user="`whoami`"
if [ "$user" != "root" ];then
	echo "execute $0 with root !!! "
	exit 0;
fi

kill -9 `ps aux | grep "httpd" | awk "{print $2}"` > /dev/null 2>&1 
kill -9 `ps aux | grep "nginx" | awk "{print $2}"` > /dev/null 2>&1 
rm -rf /usr/local/nginx
rm -f /etc/init.d/nginx

sed -i 's/^exclude/#exclude/'  /etc/yum.conf && yum -y install gcc && sed -i 's/^#exclude/exclude/'  /etc/yum.conf

##Downloading
yum -y install git gcc gcc-c++ autoconf automake make
yum -y install zlib zlib-devel openssl openssl--devel pcre pcre-devel


echo "============================= check files ==================================="
##tengine 
if [ -s tengine-1.4.6.tar.gz ]; then
	echo "tengine-1.4.6.tar.gz [found]"
else
	echo "Error: tengine-1.4.6.tar.gz not found!!!download now......"
	wget -c http://tengine.taobao.org/download/tengine-1.4.6.tar.gz
fi
tar -zxvf tengine-1.4.6.tar.gz -C /tmp


##lua-nginx-module
if [ -s lua-nginx-module  ]; then         
	echo "lua-nginx-module  [found]"
else
	echo "Error: lua-nginx-module  not found!!!download now......"
	git clone https://github.com/chaoslawful/lua-nginx-module.git
fi

##lua-cjson
if [ -s lua-cjson-2.1.0.tar.gz ]; then
	echo "lua-cjson-2.1.0.tar.gz  [found]"
else
	echo "Error: lua-cjson-2.1.0.tar.gz not found!!!download now......"
	wget -c http://www.kyne.com.au/~mark/software/download/lua-cjson-2.1.0.tar.gz
fi
tar -zxvf lua-cjson-2.1.0.tar.gz -C /tmp


##ngx_cache_purge
if [ -s ngx_cache_purge-2.1.tar.gz ]; then
	echo "ngx_cache_purge-2.1.tar.gz  [found]"
else
	echo "Error: ngx_cache_purge-2.1.tar.gz not found!!!download now......"
	wget -c http://labs.frickle.com/files/ngx_cache_purge-2.1.tar.gz
fi
tar -zxvf ngx_cache_purge-2.1.tar.gz -C /tmp


##pcre-8.33
wget -c http://ftp.exim.llorien.org/pcre/pcre-8.33.tar.gz
if [ -s pcre-8.33.tar.gz ]; then
	echo "pcre-8.33.tar.gz  [found]"
else
	echo "Error: pcre-8.33.tar.gz not found!!!download now......"
	wget -c http://ftp.exim.llorien.org/pcre/pcre-8.33.tar.gz
fi
tar -zxvf pcre-8.33.tar.gz -C /tmp

##openssl
wget -c http://www.openssl.org/source/openssl-1.0.1e.tar.gz
if [ -s openssl-1.0.1e.tar.gz ]; then
	echo "openssl-1.0.1e.tar.gz  [found]"
else
	echo "Error: openssl-1.0.1e.tar.gz not found!!!download now......"
	wget -c http://www.openssl.org/source/openssl-1.0.1e.tar.gz
fi
tar -zxvf openssl-1.0.1e.tar.gz -C /tmp

rm -rf /tmp/lua-nginx-module /tmp/conf /tmp/ocdn_lua /tmp/nginx_init.txt

cp nginx_init.txt /tmp/nginx_init.txt
cp -ra lua-nginx-module  /tmp
cp -ra conf /tmp
cp -ra ocdn_lua /tmp

cd /tmp 

echo "========================== check files completed ==================================="

echo "============================= tengine install ================================"
## change file before compile
sed -i 's/\"nginx/\"OpenCDN Beta/i' /tmp/tengine-1.4.6/src/core/nginx.h
sed 's/>nginx</>OpenCDN Beta</' -i /tmp/tengine-1.4.6/src/http/ngx_http_special_response.c
sed -i 's/\" NGINX_VER \"/OpenCDN beta/' /tmp/ngx_cache_purge-2.1/ngx_cache_purge_module.c

## complie nginx with new args
groupadd www
useradd -g www -s /bin/false -M www

cd /tmp/tengine-1.4.6
yum install -y lua-devel
./configure --user=www --group=www  --prefix=/usr/local/nginx --with-syslog --with-pcre=../pcre-8.33 --with-openssl=../openssl-1.0.1e --add-module=../ngx_cache_purge-2.1   --with-http_gzip_static_module --add-module=../lua-nginx-module
make && make install

echo "======================= tengine install completed ============================="


echo "========================== lua-cjson module =================================="
cd /tmp/lua-cjson-2.1.0
make && make install
cp /tmp/lua-cjson-2.1.0/cjson.so /usr/lib64/lua/5.1/
cp /tmp/lua-cjson-2.1.0/cjson.so /usr/lib/lua/5.1/


echo "========================== setting conf files =================================="
mv -ra /tmp/conf /usr/local/nginx/
chown www:www -R /usr/local/nginx/conf

mv /tmp/ocdn_lua /usr/local/nginx/
chown www:www -R /usr/local/nginx/ocdn_lua

mkdir /usr/local/nginx/ocdn_conf_bak
chown www:www -R /usr/local/nginx/ocdn_conf_bak

mkdir /home/cache/
chown www:www -R /home/cache
mkdir /home/temp/
chown www:www -R /home/temp
mkdir /home/logs/
chown www:www -R /home/logs/

token=$(echo -n "$HOSTNAME `date` $(($RANDOM %1000 + 1))" | md5sum | awk '{print $1}')
echo "token = \"$token\"" > /usr/local/nginx/ocdn_lua/token.lua

echo "======================= set auto start scripts ============================="
mv -f /tmp/nginx_init.txt /etc/init.d/nginx

chmod u+x /etc/init.d/nginx
chmod u+s /usr/local/nginx/sbin/nginx

chkconfig --add nginx
chkconfig --level 345 nginx on
chkconfig --list nginx

#service nginx start

echo "============================== clean ====================================="
cd /tmp 
rm -rf tengine-1.4.6* lua-cjson-2.1.0* lua-nginx-module* ngx_cache_purge-2.1* openssl-1.0.1e* pcre-8.33*
