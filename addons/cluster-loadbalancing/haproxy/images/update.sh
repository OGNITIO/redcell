#!/bin/bash

while true
do
    python /usr/local/bin/servicerouter.py \
           --marathon http://$MARATHON_URL:$MARATHON_PORT \
           --haproxy-config /etc/haproxy/haproxy.cfg
    sleep 15
done
