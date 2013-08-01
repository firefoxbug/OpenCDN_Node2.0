#!/bin/bash

# Function : uninstall opencdn node 
# author : firefoxbug
# E-Mail : wanghuafire@gmail.com
# Blog   : www.firefoxbug.net

echo "  ___                    ____ ____  _   _ 
 / _ \ _ __   ___ _ __  / ___|  _ \| \ | |
| | | | '_ \ / _ \ '_ \| |   | | | |  \| |
| |_| | |_) |  __/ | | | |___| |_| | |\  |
 \___/| .__/ \___|_| |_|\____|____/|_| \_|
  
"

get_char()
{
	SAVEDSTTY=`stty -g`
	stty -echo
	stty cbreak
	dd if=/dev/tty bs=1 count=1 2> /dev/null
	stty -raw
	stty echo
	stty $SAVEDSTTY
}

echo "Press any key to start uninstall opencdn , please wait ......"
char=`get_char`

service nginx stop
service opencdn stop

OPENCDN_PATH="/usr/local/opencdn"
NGX_PATH="/usr/local/nginx"
OPENCDN_LOG_PATH="/var/log/opencdn"

chkconfig --del opencdn
chkconfig --del nginx

rm -rf ${OPENCDN_LOG_PATH}
rm -rf ${NGX_PATH}
rm -rf ${OPENCDN_PATH}
rm -f /etc/init.d/opencdn
rm -f /etc/init.d/nginx
rm -f /var/run/nginx.pid
rm -f /var/run/opencdn.pid