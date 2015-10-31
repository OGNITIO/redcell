#
# Chronos Dockerfile
#

FROM mesosphere/mesos:0.25.0-0.2.70.ubuntu1404

MAINTAINER Lucien Zagabe <rz@ognitio.com>

ENV CHRONOS_VERSION 2.3.4

RUN apt-get update && apt-get -y install chronos curl
RUN rm -rf /etc/mesos
RUN rm -rf /etc/chronos/conf

