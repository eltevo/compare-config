Visit the [Kooplex page](https://kooplex.github.io/) for further informations!

## Prerequisites

* apt install docker.io docker-compose acl
* vim /etc/docker/daemon.json
```
{
          "exec-opts": ["native.cgroupdriver=systemd"], # for monitoring with grafana
            "log-driver": "json-file",   # don't let logs grow too large
              "log-opts": {
                          "max-size": "100m"
                            },
              "storage-driver": "overlay2",   # that was recommended at some point
      "insecure-registries":["##OTHER_KOOPLEX_INSTANCE##:5000"]  # In case of having multiple Kooplex instances, you may want reuse already built notebook images

}
```

## Kooplex configuration scripts

To install a kooplex instance, follow steps below. Substitute $PROJECT with your project name and
$SRV with the kooplex root directory on your host machine.

## Installation

* clone this repository

    $ git clone https://github.com/kooplex/kooplex-config.git

* Create certificate and copy in into $ORIGINAL_KEYS directory with name ${PREFIX}.crt and ${PREFIX}.key

* copy config.sh_template to config.sh and modify it as necessary. Here are the variables explained:


```bash
#The url that will be accessible from a browser
OUTERHOSTNAME="example.org"
OUTERHOSTPORT="89"

#The host name of a gateway or virtual host if there is any. If not use outerhost
#INNERHOST=$OUTERHOSTNAME
INNERHOST="192.168.1.15"
#If you can communicate through only one port on the outerhost then you have
#to create an extra nginx (e.g. in a container, because you will need to
#have access to certain ports in your inner network

PREFIX="aprefix"
PROJECT="projectname"

#Access to docker 
DOCKERIP="/var/run/docker.sock"
DOCKERPORT=""
DOCKERPROTOCOL="unix"

#Where all the homes, config files etc will be
ROOT="/srv/"$PREFIX

#and scripts needed for building images etc.
BUILDDIR=$ROOT"/build"

#Probably not needed
DISKIMG="/home/jegesm/Data/diskimg"
DISKSIZE_GB="20"
LOOPNO="/dev/loop3"
USRQUOTA=10G

#This is the subnet where the containers for services will be
SUBNET="172.20.0.0/16"

#Domain in ldap
LDAPDOMAIN=$OUTERHOSTNAME

SMTP="smtp"
SMTPPORT=25
EMAIL=

#Password for many things
DUMMYPASS=""

#This is the web protocol: http or https
REWRITEPROTO=http

#Prints out debug information on "docker logs $PROJECT-hub"
HUB_DEBUG=True

ERROR_LOG="error.log"
CHECK_LOG="check.log"	

#Executables
DOCKER_COMPOSE="docker-compose"
```
* For many of the following steps here you will need write access to the $ROOT and $BUILDDIR folders
* Individual modules can be installed, started etc. by specifying the module name, e.g.

    $ sudo bash kooplex.sh start proxy
    
starts the proxy only. Multiple module names can be listed or if left empty then will iterate on $SYSMODULES and $MODULES.

Manual install steps

* build (creates images and config files)
* install (creates containers out of images and runs maybe a script)
* start (starts containers)
* init (runs scripts in the containers, initializes 

Recommended :)  Install sequence is the following:

* sudo bash kooplex.sh build 
* sudo bash kooplex.sh install
* sudo bash kooplex.sh start
* sudo bash kooplex.sh init
* sudo bash kooplex.sh build hub
* sudo bash kooplex.sh install hub (after that use only "refresh hub")
* sudo bash kooplex.sh start hub
* sudo bash kooplex.sh init hub


## Proxy configuration of the $OUTERHOST or $INNERHOST if there are two layers

* add following lines to configuration file _default_ of nginx _host_ 
 
  (e.g. /etc/nginx/sites-available/default):

```
map $http_upgrade $connection_upgrade {
	default upgrade;
	'' close;
}

server {
    listen $INNERHOST:80;
    server_name $INNERHOSTNAME;
    location / {
    	proxy_set_header      Host $http_host;
        proxy_pass http://$NGINXIP/;
    }
    
    location ~* /(api/kernels/[^/]+/(channels|iopub|shell|stdin)|terminals/websocket)/? {
        proxy_pass http://$NGINXIP;
        proxy_set_header      Host $host;
        # websocket support
        proxy_http_version    1.1;
        proxy_set_header      Upgrade $http_upgrade;
        proxy_set_header      Connection $connection_upgrade;
    }
    
    #In chrome the kernel stays busy, but if...
    location ~* /(api/sessions)/? {
        proxy_pass http://$NGINXIP;
        proxy_set_header      Host $host;
        # websocket support
        proxy_http_version    1.1;
        proxy_set_header      Upgrade $http_upgrade;
        proxy_set_header      Connection $connection_upgrade;
    }

}
```

## IMPORTANT NOTES
* Check whether all the necessary ports are open (ufw allow etc) e.g. docker port, http port

## Remove containers

    $ bash kooplex.sh stop all
    $ bash kooplex.sh remove all
    
Manual remove steps:

* remove (containers)
* purge (configuration files, datatabases and directories)
* clean (deletes images)
    
## Purge configuration files, datatabases and directories

To remove ALL data and config

    $ bash kooplex.sh purge all
    
To delete generated docker images

    $ bash kooplex.sh clean all
