=========================INTROUCDE====================

1.Full free CDN deployment tools, including CDN nodes management platform and accelerate the deployment package. OpenCDN provides a convenient tool builders, real-time self-creation of CDN acceleration services

2.OpenCDN is Based on nginx + proxy_cache cache module, without operator profiles, click the mouse to set up high availability CDN acceleration system

3.OpenCDN management center capable of operating status of each node, the system load and network traffic in real-time monitoring and unified management and control node's cache strategy to synchronize all the nodes


====================BEFORE INSTALL=====================

1.OpenCDN2.0 provides centralized control center, no longer need to deploy separate control center.After you install OpenCDN2.0 Node software on your multiple CDN nodes,you can visit our official website to manage your CDN nodes.

2.OpenCDN2.0 Console center communicates with CDN nodes by TCP port 80 default,but if it doesn't work,communication port will change to 9242 automatically.

3.OpenCDN2.0 Node installtion will uninstall your nginx and stop httpd running.Be careful before you install.


====================INSTALL on Linux====================

Platform : CentOS 5.X CentOS 6.x 32bits 64bits

	wget https://github.com/firefoxbug/OpenCDN2.0/archive/master.zip
	unzip master.zip
	cd OpenCDN2.0-master/
	./install.sh

========================USEAGE============================

After install you will get a token which identifys your host.

	service opencdn start
	service nginx start

Visit http://opencdn.secon.me/login

====================UNINSTALL==========================

	./unstall.sh
