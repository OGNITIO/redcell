#!/bin/bash

# Checking if all the packages are well installed

ARRAY=
COUNTER=0

for var in "$@"
do
    dpkg --get-selections | grep -w $var > /dev/null
    if [ $? != 0 ]; then
        ARRAY[$COUNTER]=$var
        let COUNTER=COUNTER+1
    fi
done

if [ $ARRAY ]; then
    echo "The follwing package aren't installed : "
    for pkg in "${ARRAY[@]}"; do
        echo "$pkg"
    done
    exit 1
fi

exit 0
