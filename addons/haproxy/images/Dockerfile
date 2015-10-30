#
# Haproxy Dockerfile
#

FROM python:2.7.10

MAINTAINER Lucien Zagabe <rz@ognitio.com>

##
## System requierement installation
##

RUN apt-get update

RUN apt-get install -y wget

##
## Application prerequisites installation
##

RUN sed -i 's/^# \(.*-backports\s\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get install -y haproxy && \
  sed -i 's/^ENABLED=.*/ENABLED=1/' /etc/default/haproxy && \
  rm -rf /var/lib/apt/lists/*

RUN wget -O /tmp/marathon.tar.gz https://github.com/mesosphere/marathon/archive/master.tar.gz \
    && tar xvf /tmp/marathon.tar.gz -C /tmp \
    && mv /tmp/marathon-master/bin/servicerouter.py /usr/local/bin

ADD haproxy.cfg /etc/haproxy/haproxy.cfg
ADD run.sh /run.sh
ADD update.sh /update.sh

RUN pip install --no-cache-dir requests

WORKDIR /etc/haproxy

# Expose ports.
# EXPOSE 80
# EXPOSE 443
