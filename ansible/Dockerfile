# Redcell install Dockerfile
FROM debian:jessie

MAINTAINER Lucien Zagabe <rz@ognitio.com>

# Install dependencies
RUN apt-get update \
    && apt-get install -y ansible \
    && rm -rf /var/lib/apt/lists/*

ADD . /srv/redcell
WORKDIR /srv/redcell

CMD ansible-playbook -i hosts.localhost test.yml --connection=local --tags "configuration,packages"
