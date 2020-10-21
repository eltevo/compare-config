#!/bin/bash


case $VERB in
  "build")
      echo "1. Configuring ${PREFIX}-${MODULE_NAME}..." >&2
#FIXME: all seafile persistent directories are handled together, split conf/data/log
#      mkdir_svcconf
#      mkdir_svclog
      mkdir_svcdata

      sed -e s,##PREFIX##,$PREFIX, \
          -e s,##SERVICENODE##,${SERVICE_NODE}, \
          -e s,##MODULE_NAME##,$MODULE_NAME, \
          -e s,##FQDN##,$FQDN, \
	  -e s,##SEAFILE_MYSQL_ROOTPW##,$SEAFILEDB_PW, \
	  -e s,##SEAFILE_ADMIN##,$SEAFILEADMIN, \
	  -e s,##SEAFILE_ADMINPW##,$SEAFILEADMIN_PW, \
	  build/seafile-pods.yaml-template > $BUILDMOD_DIR/seafile-pods.yaml

      sed -e s,##PREFIX##,$PREFIX, \
          -e s,##MODULE_NAME##,$MODULE_NAME, \
	  build/seafile-svcs.yaml-template > $BUILDMOD_DIR/seafile-svcs.yaml

  ;;

  "init")
      echo "Initiaizing services of ${PREFIX}-${MODULE_NAME}" >&2
      STATE=$(kubectl get pods | awk "/^${PREFIX}-${MODULE_NAME}\s/ {print \$3}")
      if [ "$STATE" = "Running" ] ; then
          register_module_in_hydra
          sed -e s,##REWRITEPROTO##,$REWRITEPROTO, \
              -e s,##PREFIX##,$PREFIX, \
              -e s,##FQDN##,$FQDN, \
              -e s,##SEAFILEDB_PW##,$SEAFILEDB_PW, \
              -e s,##URL_HYDRA##,$REWRITEPROTO://$FQDN/hydra, \
              -e s,##HYDRA_CLIENTID##,${CLIENT}, \
              -e s,##DJANGO_SECRET_KEY##,$(echo $DJANGO_SECRET_KEY | sed -e 's/\$/$$/g'), \
              -e s,##HYDRA_CLIENTSECRET##,$SECRET, \
	  conf/seahub_settings.py-template > $BUILDMOD_DIR/seahub_settings.py
	  kubectl cp $BUILDMOD_DIR/seahub_settings.py helper:/data/seafile/seafile/seafile/conf/seahub_settings.py
      else
          echo "Pod for $MODULE_NAME is not running" >&2
      fi
  ;;

  "install")
      register_module_in_nginx
  ;;

  "start")
      echo "Starting services of ${PREFIX}-${MODULE_NAME}" >&2
      kubectl apply -f $BUILDMOD_DIR/seafile-svcs.yaml
      echo "Starting pods of ${PREFIX}-${MODULE_NAME}" >&2
      kubectl apply -f $BUILDMOD_DIR/seafile-pods.yaml
  ;;


  "stop")
      echo "Deleting pods of ${PREFIX}-${MODULE_NAME}" >&2
      kubectl delete -f $BUILDMOD_DIR/seafile-pods.yaml
  ;;

  "remove")
      echo "Deleting services of ${PREFIX}-${MODULE_NAME}" >&2
      kubectl delete -f $BUILDMOD_DIR/seafile-svcs.yaml
  ;;

  "purge")
      echo "Removing $BUILDMOD_DIR" >&2
      rm -R -f $BUILDMOD_DIR
      purgedir_svc
  ;;

esac

