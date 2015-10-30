#
# Telegraf Dockerfile
#

FROM golang:1.5.1

MAINTAINER Eddy Zagabe <zagabe.ed@gmail.com>

# Tmp folder creation for telegraf
RUN mkdir -p /tmp/telegraf
ENV TELEGRAF_VERSION 0.1.9

# Install utilities
Run apt-get update && apt-get install -y \
    wget \
    gzip

# Download and installation of Telegraf plugin
WORKDIR /go/src/github.com/influxdb
RUN wget https://github.com/OGNITIO/telegraf/archive/rzagabe.tar.gz
RUN gzip -d rzagabe.tar.gz && tar xf rzagabe.tar
RUN mv telegraf-rzagabe telegraf
RUN cd /go/src/github.com/influxdb/telegraf && make && cp telegraf /usr/bin/

# Configuration of Telegraf
ADD ./telegraf.conf /tmp/telegraf/telegraf.conf
ADD ./run.sh /tmp/telegraf/run.sh

CMD ["bash", "/tmp/telegraf/run.sh", "/tmp/telegraf/telegraf.conf"]
