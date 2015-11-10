#!/bin/bash

apt-get update && apt-get install -y sudo

adduser admin
adduser admin sudo

echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

su - admin
mkdir -p /home/admin/.ssh
curl --fail --silent -H 'Metadata-Flavor: Google' "http://metadata/computeMetadata/v1/instance/attributes/admin_key" > /home/admin/.ssh/authorized_keys
