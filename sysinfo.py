#-*- coding: utf-8 -*-

import os
import re
import time
import datetime
import socket
import fcntl
import struct
import subprocess
from os.path import join, getsize

def b2h(num):
	for x in ['Byte','kByte','MByte', 'GByte', 'TByte', 'PByte', 'EByte', 'ZByte', 'YByte']:
		if num < 1024.0:
			return "%3.2f %s" % (num, x)
		num /= 1024.0

def bytes2bits(num):
	for x in ['Bit/s','KBit/s', 'MBit/s', 'GBit/s', 'TBit/s', 'PBit/s', 'EBit/s', 'ZBit/s', 'YBit/s']:
		if num < 1024.0:
			return "%3.2f %s" % (num, x)
		num /= 1024.0

def div_percent(a, b):
	if b == 0: return '0%'
	return '%.2f%%' % (round(float(a)/b, 4) * 100)


class Server(object):
	@classmethod
	def meminfo(self):
		# OpenVZ may not have some varirables
		# so init them first
		mem_total = mem_free = mem_buffers = mem_cached = swap_total = swap_free = 0

		f = open('/proc/meminfo', 'r')
		if f:
			for line in f:
				if ':' not in line: continue
				item, value = line.split(':')
				value = int(value.split()[0]) * 1024;
				if item == 'MemTotal':
					mem_total = value
				elif item == 'MemFree':
					mem_free = value
				elif item == 'Buffers':
					mem_buffers = value
				elif item == 'Cached':
					mem_cached = value
				elif item == 'SwapTotal':
					swap_total = value
				elif item == 'SwapFree':
					swap_free = value

		mem_used = mem_total - mem_free
		swap_used = swap_total - swap_free
		return {
			'mem_total': b2h(mem_total),
			'mem_used': b2h(mem_used),
			'mem_free': b2h(mem_free),
			'mem_buffers': b2h(mem_buffers),
			'mem_cached': b2h(mem_cached),
			'swap_total': b2h(swap_total),
			'swap_used': b2h(swap_used),
			'swap_free': b2h(swap_free),
			'mem_used_rate': div_percent(mem_used, mem_total),
			'mem_free_rate': div_percent(mem_free, mem_total),
			'swap_used_rate': div_percent(swap_used, swap_total),
			'swap_free_rate': div_percent(swap_free, swap_total),
		}

	@classmethod
	def netifaces(self):
		netifaces = []
		f = open('/proc/net/dev', 'r')
		if f:
			for line in f:
				if not ':' in line: continue
				name, data = line.split(':')
				name = name.strip()
				data = data.split()
				rx = int(data[0])
				tx = int(data[8])
				netifaces.append({
					'name': name,
					'rx': b2h(rx),
					'tx': b2h(tx),
					'timestamp': int(time.time()),
					'rx_bytes': rx,
					'tx_bytes': tx,
				})
		f.close()
		f = open('/proc/net/route')
		if f:
			for line in f:
				fields = line.strip().split()
				if fields[1] != '00000000' or not int(fields[3], 16) & 2:
					continue
				gw = socket.inet_ntoa(struct.pack('<L', int(fields[2], 16)))
				for netiface in netifaces:
					if netiface['name'] == fields[0]:
						netiface['gw'] = gw
						break
		# REF: http://linux.about.com/library/cmd/blcmdl7_netdevice.htm
		f.close()
		for i, netiface in enumerate(netifaces):
			guess_iface = False
			while True:
				try:
					ifname = netiface['name'][:15]
					ifnamepack = struct.pack('256s', ifname)
					s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
					sfd = s.fileno()
					flags, = struct.unpack('H', fcntl.ioctl(
						sfd, 0x8913,  # SIOCGIFFLAGS
						ifnamepack
					)[16:18])
					netiface['status'] = ('down', 'up')[flags & 0x1]
					netiface['ip'] = socket.inet_ntoa(fcntl.ioctl(
						sfd, 0x8915,  # SIOCGIFADDR
						ifnamepack
					)[20:24])
					netiface['bcast'] = socket.inet_ntoa(fcntl.ioctl(
						sfd, 0x8919,  # SIOCGIFBRDADDR
						ifnamepack
					)[20:24])
					netiface['mask'] = socket.inet_ntoa(fcntl.ioctl(
						sfd, 0x891b,  # SIOCGIFNETMASK
						ifnamepack
					)[20:24])
					hwinfo = fcntl.ioctl(
						sfd, 0x8927,  # SIOCSIFHWADDR
						ifnamepack)
					# REF: networking/interface.c, /usr/include/linux/if.h, /usr/include/linux/if_arp.h
					encaps = {
						'\xff\xff': 'UNSPEC',                   # -1
						'\x01\x00': 'Ethernet',                 # 1
						'\x00\x02': 'Point-to-Point Protocol',  # 512
						'\x04\x03': 'Local Loopback',           # 772
						'\x08\x03': 'IPv6-in-IPv4',             # 776
						'\x20\x00': 'InfiniBand',               # 32
					}
					hwtype = hwinfo[16:18]
					netiface['encap'] = encaps[hwtype]
					netiface['mac'] = ':'.join(['%02X' % ord(char) for char in hwinfo[18:24]])
	
					if not netiface['name'].startswith('venet'): break

					# detect interface like venet0:0, venet0:1, etc.
					if not guess_iface:
						guess_iface = True
						guess_iface_name = netiface['name']
						guess_iface_i = 0
					else:
						netifaces.append(netiface)
						guest_iface_i += 1

					netiface = {
						'name': '%s:%d' % (guess_iface_name, guess_iface_i),
						'rx': '0B',
						'tx': '0B',
						'timestamp': 0,
						'rx_bytes': 0,
						'tx_bytes': 0,
					}
				except:
					#netifaces[i] = None
					break
				
		netifaces = [ iface for iface in netifaces if iface.has_key('mac') ]
		return netifaces

def getdirsize(dir):
	size = 0L
	for root, dirs, files in os.walk(dir):
		try :
			size += sum([getsize(join(root, name)) for name in files])
		except :
			pass
	return size

def get_cache_size(cache_path):
	filesize = getdirsize(cache_path)
#	print 'There are %.2f %s' %(filesize,b2h(filesize))
	return filesize,b2h(filesize)

'''
cpu|usage
memory|total|used|usage
cache|cache_size(bytes)|cache_size(string)
interface|name1|ip|total_recv(bytes)|total_recv(string)|recv_rates|total_sent(bytes)|total_sent(converted)|sent_rates
interface|name2|ip|total_recv(bytes)|total_recv(string)|recv_rates|total_sent(bytes)|total_sent(converted)|sent_rates
.
.
.

	interface|%s|%s|%s|%s|%s|%s|%s|%s
'''
def system_info():

	cpu_line = os.popen('top -bi -n 2').read().split('\n\n\n')[1].split('\n')[2]
	cpu_usage = float(re.split(':|,|%',cpu_line)[1])
#	print "* CPU usage : %.1f%%"%(cpu_usage)

	meminfo = Server.meminfo()

#	print '* Memory total: %s' % meminfo['mem_total']
#	print '* Memory used: %s (%s)' % (meminfo['mem_used'], meminfo['mem_used_rate'])

	cache_path = "/home/cache"
	cache,cache_h = get_cache_size(cache_path)

	sysinfo_cmd = '''cpu|%s%%\nmemory|%s|%s|%s\ncache|%s|%s\n'''%(cpu_usage,meminfo['mem_total'],meminfo['mem_used'],meminfo['mem_used_rate'],cache,cache_h)
	
	sysinfo_cmd = sysinfo_cmd + network_flow()
	print sysinfo_cmd
	sys_info_path = "/usr/local/opencdn/node/sysinfo.txt"
	os.system("echo \"%s\" > %s"%(sysinfo_cmd,sys_info_path))
#	disk_stat()

def network_flow():
	time2sleep = 1
	start = time.time()
	netifaces_old = Server.netifaces()

	time.sleep(1)

	netifaces = Server.netifaces()
	end = time.time()
	elapsed = end - start

	i = 0
	network_str = ""
	for netiface in netifaces:
		netiface_old = netifaces_old[i]
#		print '* Interface name: %s' % netiface['name']
#		print '* IP address: %s' % netiface['ip']
		recv_rate = (netiface['rx_bytes']-netiface_old['rx_bytes'])/elapsed
		send_rate = (netiface['tx_bytes']-netiface_old['tx_bytes'])/elapsed
		recv_rate2h = bytes2bits(recv_rate*8)
		send_rate2h = bytes2bits(send_rate*8)
#		print '* Data receive: %d %s %s' % (netiface['rx_bytes'],netiface['rx'],recv_rate2h)
#		print '* Data transmit: %d %s %s' % (netiface['tx_bytes'],netiface['tx'],send_rate2h)
		network_str = network_str + 'interface|%s|%s|%s|%s|%s|%s|%s|%s\n'%(netiface['name'],netiface['ip'],netiface['rx_bytes'],netiface['rx'],recv_rate2h,netiface['tx_bytes'],netiface['tx'],send_rate2h)
#		print
		i = i + 1
	return network_str

if __name__ == '__main__':
#	system_info()
	
	while True:
#		network_flow()
		system_info()