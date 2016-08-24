#!/bin/bash

case $VERB in
  "build")
    echo "Building image kooplex-owncloud"
    
    docker $DOCKERARGS build -t kooplex-owncloud .
  ;;
  "install")
    echo "Installing owncloud $PROJECT-owncloud [$OWNCLOUDIP]"
    
    # Create owncloud container. We need to setup ldap as well
    docker $DOCKERARGS create \
      --name $PROJECT-owncloud \
      --hostname $PROJECT-owncloud \
      --net $PROJECT-net \
      --ip $OWNCLOUDIP \
      -p 90:80 \
      -p 91:9000 \
      --privileged \
      kooplex-owncloud
  ;;
  "start")
  #
  docker start $PROJECT-owncloud
  ;;
  "init")
    
  ;;
  "stop")
    echo "Stopping owncloud $PROJECT-owncloud [$OWNCLOUDIP]"
    docker $DOCKERARGS stop $PROJECT-owncloud
  ;;
  "remove")
    echo "Removing owncloud $PROJECT-owncloud [$OWNCLOUDIP]"
    docker $DOCKERARGS rm $PROJECT-owncloud
  ;;
  "purge")
    echo "Purging owncloud $PROJECT-owncloud [$OWNCLOUDIP]"
    rm -R $SRV/owncloud
  ;;
  "clean")
    echo "Cleaning base image kooplex-owncloud"
    docker $DOCKERARGS rmi kooplex-owncloud
  ;;
esac