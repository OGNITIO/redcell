#
# Riemann Dockerfile
#

FROM debian:jessie

MAINTAINER Lucien Zagabe <rz@ognitio.com>

##
## System requierements installation
##

RUN apt-get update
RUN apt-get install -y curl wget

###
### Application prerequisites installation
###

ENV RIEMANN_REQS openjdk-7-jdk default-jre-headless
RUN apt-get update \
 && apt-get install -y $RIEMANN_REQS \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

ENV RIEMANN_VERSION 0.2.10
RUN wget -O /tmp/riemann_${RIEMANN_VERSION}_all.deb http://aphyr.com/riemann/riemann_${RIEMANN_VERSION}_all.deb
RUN dpkg -i /tmp/riemann_${RIEMANN_VERSION}_all.deb

ADD conf/riemann.config /etc/riemann/riemann.config
