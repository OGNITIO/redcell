#!/bin/bash

path=$1

if [ -d /mnt/proc ]; then
    umount /proc
    mount -o bind /mnt/proc /proc
fi

/usr/bin/telegraf -config $path
