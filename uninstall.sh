#!/bin/bash

# author : firefoxbug
# E-Mail : wanghuafire@gmail.com
# Blog   : www.firefoxbug.net

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
