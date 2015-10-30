#
# Registry proxy
#

FROM golang:1.5.1

MAINTAINER Eddy Zagabe <zagabe.ed@gmail.com>

# Install necessary software
RUN apt-get update && apt-get install -y \
    curl \
    gzip

# Download the registry-proxy archive
WORKDIR $GOPATH/src/github.com/rzagabe
RUN wget https://api.github.com/repos/rzagabe/proxy/tarball
RUN mv tarball tarball.tar.gz && tar xvf tarball.tar.gz && mv rzagabe-proxy-* proxy
WORKDIR $GOPATH/src/github.com/rzagabe/proxy

# Install and configure the proxy
RUN go get github.com/golang/glog
RUN go install

# Main command
CMD $GOPATH/bin/proxy -from localhost:$FORWARD_PORT -to $REGISTRY_HOST:$REGISTRY_PORT
