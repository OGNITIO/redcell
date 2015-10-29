#
# Grafana Dockerfile
#

FROM debian:jessie

MAINTAINER Lucien Zagabe <rz@ognitio.com>

##
## System requierement installation
##

RUN apt-get update

RUN apt-get install -y wget

##
## Application prerequisites installation
##

ENV GRAFANA_REQS adduser libfontconfig wget
RUN apt-get update \
 && apt-get install -y $GRAFANA_REQS \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN wget -O /tmp/grafana_2.1.3_amd64.deb https://grafanarel.s3.amazonaws.com/builds/grafana_2.1.3_amd64.deb
RUN dpkg -i /tmp/grafana_2.1.3_amd64.deb
ADD conf/defaults.ini /etc/grafana/grafana.ini
ADD conf/defaults.ini /conf/defaults.ini

CMD ["echo done"]
