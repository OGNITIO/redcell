#
# InfluxDB Dockerfile
#

FROM debian:jessie

MAINTAINER Lucien Zagabe <rz@ognitio.com>

##
## System requierement installation
##

RUN apt-get update

RUN apt-get install -y curl

##
## Application prerequisites installation
##

ENV INFLUXDB_VERSION 0.9.4.2
RUN curl -s -o /tmp/influxdb_latest_amd64.deb https://s3.amazonaws.com/influxdb/influxdb_${INFLUXDB_VERSION}_amd64.deb && \
  dpkg -i /tmp/influxdb_latest_amd64.deb && \
  rm /tmp/influxdb_latest_amd64.deb && \
  rm -rf /var/lib/apt/lists/*

ADD types.db /usr/share/collectd/types.db
ADD config.toml /config/config.toml
ADD run.sh /run.sh
RUN chmod +x /*.sh

ENV PRE_CREATE_DB **None**
ENV SSL_SUPPORT **False**
ENV SSL_CERT **None**

CMD ["echo done"]
