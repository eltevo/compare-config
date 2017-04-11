#!/bin/bash

# try to allocate dashboards server ports from this port value
DASHBOARDS_PORT=3000


DOCKER_HOST=$DOCKERARGS

case $VERB in
  "build")
    for DOCKER_FILE in ../notebook/image*/Dockerfile-*
    do
      POSTFIX=${DOCKER_FILE##*Dockerfile-}
      DOCKER_COMPOSE_FILE=docker-compose.yml-$POSTFIX

      echo "1. Building dockerfile file for $POSTFIX..."
      IMAGE=kooplex-notebook-$POSTFIX
      KGW_DOCKERFILE=Dockerfile.kernel-$POSTFIX
#TODO: check the existance of the docker image by docker images
      sed -e "s/##IMAGE##/$IMAGE/" Dockerfile.kernel.template > $KGW_DOCKERFILE

      echo "2. Building compose file $DOCKER_COMPOSE_FILE..."
      KGV=kernel-gateway-$POSTFIX
#FIXME: these are hard coded
      VOL="\/srv\/kooplex\/mnt_kooplex\/compare\/dashboards\/$POSTFIX\/"
      NETWORK=compare-net
      sed -e "s/##KERNELGATEWAY##/$KGV/" \
          -e "s/##KERNELGATEWAY_DOCKERFILE##/$KGW_DOCKERFILE/" \
          -e "s/##VOLUME##/$VOL/" \
          -e "s/##NETWORK##/$NETWORK/" \
        docker-compose.yml.KGW_template > $DOCKER_COMPOSE_FILE
#TODO: when more dashboards do a loop here
      DASHBOARDS_NAME=kooplex-dashboards-$POSTFIX
      sed -e "s/##KERNELGATEWAY##/$KGV/" \
          -e "s/##DASHBOARDS##/$DASHBOARDS_NAME/" \
          -e "s/##VOLUME##/$VOL/" \
          -e "s/##DASHBOARDS_PORT##/$DASHBOARDS_PORT/" \
        docker-compose.yml.DBRD_template >> $DOCKER_COMPOSE_FILE
      DASHBOARDS_PORT=$((DASHBOARDS_PORT + 1))   
#NOTE: inner loop over dashboards for a given gateway should end here

      echo "3. Building images for $POSTFIX..."
      docker-compose $DOCKER_HOST -f $DOCKER_COMPOSE_FILE build 
   done
  ;;

  "install")
  ;;

  "start")  
    for DOCKER_COMPOSE_FILE in docker-compose.yml-*
    do
      echo "Starting service for $DOCKER_COMPOSE_FILE"
      docker-compose $DOCKERARGS -f $DOCKER_COMPOSE_FILE up -d
    sleep 2
   done
  ;;

  "init")  
  ;;

  "stop")
    for DOCKER_COMPOSE_FILE in docker-compose.yml-*
    do
      echo "Stopping and removing services in $DOCKER_COMPOSE_FILE"
      docker-compose $DOCKERARGS -f $DOCKER_COMPOSE_FILE down
    done
  ;;
    
  "remove")
    for DOCKER_COMPOSE_FILE in docker-compose.yml-*
    do
      POSTFIX=${DOCKER_COMPOSE_FILE##*docker-compose.yml-}
      echo "Removing $DOCKER_COMPOSE_FILE"
      docker-compose $DOCKERARGS -f $DOCKER_COMPOSE_FILE kill
      docker-compose $DOCKERARGS -f $DOCKER_COMPOSE_FILE rm
#FIXME: should not we remove images and generated Dockerfiles?
    done
  ;;

  "purge")
    echo "Removing $SRV/dashboard" 
    rm -R -f $SRV/dashboards
  ;;

  "clean")
  ;;
esac
