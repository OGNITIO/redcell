#!/bin/bash

HOSTIPNAME=$(ip a show dev eth0 | grep inet | grep eth0 | sed -e 's/^.*inet.//g' -e 's/\/.*$//g')
sed -i "s/.*listener.*/    \"listener\":\"$HOSTIPNAME\",/g" /usr/local/mesos-dns/config.json

/usr/local/mesos-dns/mesos-dns $@
