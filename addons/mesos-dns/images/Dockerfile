#
# Mesos DNS Dockerfileg
#

FROM golang:1.5.1

MAINTAINER Lucien Zagabe <rz@ognitio.com>

##
## System requirements installation
##

### Update apt repository
RUN apt-get update

### Install python prerequisites
RUN apt-get install -y python-pip python-dev build-essential

### Install Thermos prerequisites
ENV THERMOS_REQS libcurl4-nss-dev \
                 libc6-dev \
                 libsvn-dev \
                 libsasl2-dev \
                 libapr1-dev \
                 zlib1g-dev \
                 libc6
RUN apt-get install -y $THERMOS_REQS

##
## System prerequisites configuration
##

RUN go get github.com/mesosphere/mesos-dns
RUN cd /go/src/github.com/mesosphere/mesos-dns \
    && go build . \
    && mkdir /usr/local/mesos-dns \
    && mv mesos-dns /usr/local/mesos-dns
ADD conf/config.json /usr/local/mesos-dns/config.json
ADD include/run.sh /run.sh

CMD ["echo done"]
