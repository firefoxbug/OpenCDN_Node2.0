#!/bin/bash

# author : firefoxbug
# E-Mail : wanghuafire@gmail.com
# Blog   : www.firefoxbug.net

## Check user permissions ##
if [ $(id -u) != "0" ]; then
	echo "Error: NO PERMISSION! Please login as root to install MAPn."
	exit 1
fi

function killd_server()
{
	kill -9 `ps aux | grep "httpd" | awk "{print $2}"` > /dev/null 2>&1 
	kill -9 `ps aux | grep "nginx" | awk "{print $2}"` > /dev/null 2>&1 

	rpm -e httpd
	rpm -e nginx
	rm -f /etc/init.d/opencdn
	rm -f /etc/init.d/nginx
	rm -f /var/run/nginx.pid
	rm -rf /usr/local/nginx
	rm -rf /usr/local/opencdn
}

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

function get_system_basic_info()
{
	echo "  ___                    ____ ____  _   _ 
 / _ \ _ __   ___ _ __  / ___|  _ \| \ | |
| | | | '_ \ / _ \ '_ \| |   | | | |  \| |
| |_| | |_) |  __/ | | | |___| |_| | |\  |
 \___/| .__/ \___|_| |_|\____|____/|_| \_|
      |_|                                 
"
	echo ""
	echo "Press any key to start install opencdn , please wait ......"
	char=`get_char`

	IS_64=`uname -a | grep "x86_64"`
	if [ -z "${IS_64}" ]
	then
		CPU_ARC="i386"
	else
		CPU_ARC="x86_64"
	fi

	IS_5=`cat /etc/redhat-release | grep "5.[0-9]"`
	if [ -z "${IS_5}" ]
	then
		VER="6"
		rpm_ver="epel-release-6-8.noarch.rpm"
	else
		VER="5"
		rpm_ver="epel-release-5-4.noarch.rpm"
	fi
	setenforce 0
	rpm -ivh "http://dl.fedoraproject.org/pub/epel/${VER}/${CPU_ARC}/${rpm_ver}"
	yum -y install yum-fastestmirror
	yum -y install ntpdate
	/usr/sbin/ntpdate us.pool.ntp.org
	/sbin/hwclock -w
}

./uninstall.sh
get_system_basic_info

killd_server

OPENCDN_LOG_PATH="/usr/local/opencdn/log"
OPENCDN_EXEC_PATH="/usr/local/opencdn/sbin"
OPENCDN_PIPE_PATH="/usr/local/opencdn/pipe"
OPENCDN_WEB_PATH="/usr/local/opencdn/web"
OPENCDN_NODE_PATH="/usr/local/opencdn/node"

mkdir -p ${OPENCDN_LOG_PATH}
mkdir -p ${OPENCDN_EXEC_PATH}
mkdir -p ${OPENCDN_PIPE_PATH}
mkdir -p ${OPENCDN_WEB_PATH}
mkdir -p ${OPENCDN_NODE_PATH}

echo "<h1>Welcome to OpenCDN</h1>" > ${OPENCDN_WEB_PATH}/index.html

cp ./bandwidth.sh ${OPENCDN_EXEC_PATH}
chmod u+x ${OPENCDN_EXEC_PATH}/bandwidth.sh

cp ./sysinfo.py ${OPENCDN_EXEC_PATH}

bandwidth_fifo="${OPENCDN_PIPE_PATH}/bandwidth.pipe"
mkfifo $bandwidth_fifo
if [ ! -p "${bandwidth_fifo}" ] 
then
	echo "create ${bandwidth_fifo} failured!!!"
	exit 1;
fi

command_fifo="${OPENCDN_PIPE_PATH}/command.pipe"
mkfifo $command_fifo
if [ ! -p "${command_fifo}" ] 
then
	echo "create ${command_fifo} failured!!!"
	exit 1;
fi

cur_dir=`pwd`

echo "===========================nginx install start===================================="
pushd Tengine
chmod u+x ./tengine.sh
./tengine.sh
popd
echo "===========================nginx install completed================================"


chown www:www -R ${OPENCDN_WEB_PATH}

chmod u+x ${cur_dir}/opencdn
rm -f /etc/init.d/opencdn
mv -f ${cur_dir}/opencdn /etc/init.d/
chkconfig --add opencdn
service opencdn restart
service nginx start
token=$(head -1 /usr/local/nginx/ocdn_lua/token.lua | awk -F [=\"] '{print $3}')
echo "==========================OpenCDN===================================="
echo "*                                                                   *"
echo "*			service opencdn [start|stop|restart|status]	              *"
echo "*                                                                   *"
echo "==========================OpenCDN===================================="

echo -e "\n\033[31mtoken : $token \033[0m\n"

## Clean source file
