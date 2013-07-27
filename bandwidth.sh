#!/bin/bash

# Function : read from pipe count log bandwidth
# Author   : firefoxbug
# Date     : 2013/07/06

#format [$time_local] $host $body_bytes_sent $upstream_cache_status

function initial()
{
	opencdn="/usr/local/opencdn"
#	opencdn="."
	opencdn_log="${opencdn}/log"
	[ -d "$opencdn_log" ] || mkdir $opencdn_log

	opencdn_bw_log_dir="${opencdn}/stream"
	[ -d "$opencdn_bw_log_dir" ] || mkdir $opencdn_bw_log_dir

	opencdn_pipe="${opencdn}/pipe"
	[ -d "$opencdn_pipe" ] || mkdir $opencdn_pipe
	
	bw_pipe="${opencdn_pipe}/bandwidth.pipe"
	if [ ! -p "${bw_pipe}" ];then
		mkfifo "${bw_pipe}"
	fi
	exec 6<>$bw_pipe

	cmd_pipe="${opencdn_pipe}/command.pipe"
	if [ ! -p "${cmd_pipe}" ];then
		mkfifo "${cmd_pipe}"
	fi
	exec 7<>$cmd_pipe
}

# parse time_local string and format filename 
# such as "2013_07_02_18_18"
function parse_time_local()
{
	time_local=$(echo ${time_local} | tr -s ':' '/')
	eval $(echo ${time_local} | awk -F / '{printf("day=%s\nmonth=%s\nyear=%s\nhour=%s\nminute=%s\n",$1,$2,$3,$4,$5)}')
	domain_bw_file="${year}_${month}_${day}_${hour}_${minute}"
#	echo "$domain_bw_file"
}

# delte all log files which one hour before
function delete_old_log()
{
	file_delete=$(ls -1 ${domain_log_dir}/*${hour}_${minute}* | grep -v $domain_bw_file)
	[ -f "$file_delete" ] && (echo "rm -f $file_delete" ;rm -f $file_delete)	
}

# accumulate all bandwidth and update log file
function update_log_bw()
{
	domain_log_dir="${opencdn_bw_log_dir}/${domain}"
	if [ "$cache_status" == "HIT" ]
	then
		bw_one="$req_size"
		pv_one=1
		hit_bw="$req_size"
		hit_pv=1
	else
		bw_one="$req_size"
		pv_one=1
		hit_bw=0
		hit_pv=0		
	fi
#	create domain directory
	[ -d "$domain_log_dir" ] || mkdir $domain_log_dir
	domain_log_path="${domain_log_dir}/${domain_bw_file}"
	if [ -f "$domain_log_path" ]
	then
		eval $(head -1 $domain_log_path | awk -F \| '{printf("bandwidth=%d\npv=%d\nhits_bandwidth=%d\nhits_pv=%d\n",$1,$2,$3,$4)}')
		bandwidth=$(($bandwidth+$bw_one))
		pv=$(($pv+$pv_one))
		hits_bandwidth=$(($hits_bandwidth+$hit_bw))
		hits_pv=$(($hits_pv+$hit_pv))
		echo "$bandwidth|$pv|$hits_bandwidth|$hits_pv" > $domain_log_path
	else
		echo "$bw_one|$pv_one|$hit_bw|$hit_pv" > $domain_log_path
	fi
	delete_old_log
}

# parse origin log 
function parse_log()
{
	line="$1"
	eval $(echo "$line" |awk '{printf("time_local=%s\ntime_zone=%s\ndomain=%s\nreq_size=%s\ncache_status=%s",$1,$2,$3,$4,$5)}')
	time_local=$(echo ${time_local:1:17})
#	echo $time_local $time_zone $domain $req_size $cache_sttus
	parse_time_local
	domain=$(echo $domain | tr -s '.' '_')
	update_log_bw
}

# read log from pipe and parse in backstage
function log_process()
{
	while :
	do
		read -u6 log_line
		echo "$log_line" >> ${opencdn_log}/bandwidth.log
		parse_log "$log_line"
	done
}

# read shell command from pipe and excute in backstage
function shell_cmd_process()
{
	while :
	do
		read -u7 cmd_line
		echo "$cmd_line" >> ${opencdn_log}/command.log
		$cmd_line >> ${opencdn_log}/command.log 2>&1
	done
}

initial
log_process &
shell_cmd_process &