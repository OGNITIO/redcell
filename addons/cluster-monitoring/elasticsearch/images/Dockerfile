#
# Elasticsearch Dockerfile
#

FROM debian:jessie

MAINTAINER Lucien Zagabe <rz@ognitio.com>

RUN apt-get update

RUN apt-get install -y curl

RUN \
    echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee /etc/apt/sources.list.d/webupd8team-java.list \
    && echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886 \
    && apt-get update \
    && echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections \
    && echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections \
    && DEBIAN_FRONTEND=noninteractive  apt-get install -y --force-yes oracle-java8-installer oracle-java8-set-default \
    && rm -rf /var/cache/oracle-jdk8-installer \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

ENV ES_PKG_NAME elasticsearch-1.7.3

RUN cd / \
  && wget https://download.elasticsearch.org/elasticsearch/elasticsearch/$ES_PKG_NAME.tar.gz \
  && tar xvzf $ES_PKG_NAME.tar.gz \
  && rm -f $ES_PKG_NAME.tar.gz \
  && mv /$ES_PKG_NAME /elasticsearch

ADD conf/elasticsearch.yml /elasticsearch/config/elasticsearch.yml

WORKDIR /data
