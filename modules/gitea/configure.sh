#!/bin/bash


case $VERB in
  "build")
      echo "1. Configuring ${PREFIX}-${MODULE_NAME}..."
#      mkdir_svcconf
#      mkdir_svclog
      mkdir_svcdata

      ROOTURL=${REWRITEPROTO}://${FQDN}/gitea
      sed -e s,##PREFIX##,$PREFIX, \
          -e s,##KUBE_MASTERNODE##,${KUBE_MASTERNODE}, \
          -e s,##ROOTURL##,$ROOTURL, \
          -e s,##MODULE_NAME##,$MODULE_NAME, \
	  -e s,##GITEA_MYSQL_ROOTPW##,$GITEADB_PW, \
	  -e s,##GITEADB_USER##,$GITEAUSER, \
	  -e s,##GITEADB_PW##,$GITEAUSER_PW, build/gitea.yaml-template \
          > $BUILDMOD_DIR/gitea.yaml

      CONFDIR=$MODDATA_DIR/gitea/gitea/conf
      _mkdir $CONFDIR
      sed -e s,##PREFIX##,$PREFIX, \
          -e s,##FQDN##,$FQDN, \
          -e s,##ROOTURL##,$ROOTURL, \
          -e s,##GITEADB_ROOTPW##,$GITEAADMINPW, \
          -e s,##GITEADB##,$GITEADB, \
          -e s,##GITEADB_USER##,$GITEAUSER, \
          -e s,##GITEADB_PW##,$GITEAUSER_PW, etc/app.ini-template \
          > $CONFDIR/app.ini
    
  ;;

  "install")
      sed -e s,##PREFIX##,$PREFIX, etc/nginx-${MODULE_NAME}-template \
          > $SERVICECONF_DIR/nginx/conf.d/sites-enabled/${MODULE_NAME}
  ;;

  "start")
       echo "Starting containers of ${PREFIX}-${MODULE_NAME}"
       kubectl apply -f $BUILDMOD_DIR/gitea.yaml
  ;;


  "stop")
      echo "Stopping containers of ${PREFIX}-${MODULE_NAME}"
      kubectl delete -f $BUILDMOD_DIR/gitea.yaml
  ;;

  "remove")
  ;;

  "purge")
      echo "Removing $BUILDMOD_DIR" 
      rm -R -f $BUILDMOD_DIR
  ;;

esac

