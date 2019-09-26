#!/bin/sh
echo $DATABASE_URL > /tmp/vmi

lockfile=/.migrated
if [ ! -f $lockfile ]; then 
    hydra migrate sql $DATABASE_URL &&  touch $lockfile
    echo hydra migrate $DATABASE_URL &&  touch $lockfile
    echo "Migrated"
fi

hydra host --dangerous-force-http

sleep 1000000