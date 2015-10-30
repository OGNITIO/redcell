#
# Fluentd Dockerfile
#

FROM debian:jessie

MAINTAINER Lucien Zagabe <rz@ognitio.com>

##
## System requierements installation
##

RUN apt-get update

RUN apt-get install -y curl patch

# Install Ruby.
RUN apt-get update \
    && apt-get install -y ruby ruby-dev \
    && rm -rf /var/lib/apt/lists/*

##
## Application prerequisites installation
##

RUN curl https://packages.treasuredata.com/GPG-KEY-td-agent | apt-key add -
RUN echo "deb http://packages.treasuredata.com/2/debian/jessie/ jessie contrib" > /etc/apt/sources.list.d/treasure-data.list
RUN apt-get update
RUN apt-get install -y --force-yes td-agent build-essential gcc
RUN mkdir -p /td-agent/tmp # for access log pos
RUN /usr/sbin/td-agent-gem install fluent-plugin-kafka # Kafka fluentd plugin
ADD conf/fluentd.conf /etc/fluentd/fluentd.conf

CMD ["/usr/sbin/td-agent", "--config", "/etc/fluentd/fluentd.conf"]
