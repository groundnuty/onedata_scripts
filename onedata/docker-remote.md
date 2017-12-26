# Installing Onedata using docker-remote with remote VM

Most of quick-start scenarios start more then one service. Each of them has to be installed by navigating to https://<container-ip>:<didicated_port> where you configure and deploy the service via web interface. Docker creates a private network and assignes ips from this network to containers. 

In order to acess drocker private network on the remote machine you may use simple ssh port forwarding and then configure your browser to froward all trafic through specyfic port. That wasy you may access containers from your browsher as if the private docker network was on your local pc.

Since the port forwarding and browsher connection configuration is outside the scope of this documentation we provide few helpfull links:
- http://askubuntu.com/questions/469582/how-do-i-set-up-a-local-socks-proxy-that-tunnels-traffic-through-ssh
- https://arliguy.net/2013/06/18/proxy-socks-via-ssh-pour-firefox/
/Users/orzech/repos/onedata/onedata-getting-started/docker-compose-oneprovider.yml
