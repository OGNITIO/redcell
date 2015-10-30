#
# Kibana Dockerfile
#

FROM java:openjdk-7-jre

MAINTAINER Lucien Zagabe <rz@ognitio.com>

##
## System requierements installation
##

RUN apt-get update && \
    apt-get install -y curl && \
    apt-get clean

##
## Application prerequisites installation
##

RUN cd / \
    && curl -O https://download.elastic.co/kibana/kibana/kibana-4.0.2-linux-x64.tar.gz \
    && tar xf kibana-4.0.2-linux-x64.tar.gz \
    && rm kibana-4.0.2-linux-x64.tar.gz

CMD ["echo done"]
