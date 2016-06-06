#!/bin/bash

echo "Installing nginx $PROJECT-nginx [$NGINXIP]"

# Initialize nginx directory with necessary config files

mkdir -p $SRV/nginx/etc/
cp nginx.conf $SRV/nginx/etc/

# Install and execute docker image

docker run -d \
  --name $PROJECT-nginx \
  --net $PROJECT-net \
  --ip $NGINXIP \
  -v $SRV/nginx/etc/nginx.conf:/etc/nginx/nginx.conf:ro \
  -v $SRV/nginx/etc/sites.conf:/etc/nginx/sites.conf:ro \
  nginx

