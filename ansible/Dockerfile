# Redcell install Dockerfile
FROM debian:jessie

MAINTAINER Lucien Zagabe <rz@ognitio.com>

# Install dependencies
RUN apt-get update \
    && apt-get install -y ansible \
    && rm -rf /var/lib/apt/lists/*

ADD . /srv/redcell
WORKDIR /srv/redcell

RUN echo "[all]\nlocalhost var_hostname=localhost\n" > hosts

CMD ansible-playbook test.yml --connection=local
