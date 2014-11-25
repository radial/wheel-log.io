# Spoke Dockerfile for log.io

FROM            radial/spoke-base:latest
MAINTAINER      Brian Clements <radial@brianclements.net>

# Download source
ENV             NODE_VERSION v0.10.29
ENV             NODE_SRC_PATH /tmp/node-src/node-$NODE_VERSION
RUN             mkdir -p /tmp/node-src
RUN             apt-get -q update && apt-get -qyV install \
                    wget
RUN             wget -q -O - http://nodejs.org/dist/"$NODE_VERSION"/node-"$NODE_VERSION".tar.gz | tar -zx -C /tmp/node-src

# Install packages
ENV             DEBIAN_FRONTEND noninteractive
RUN             apt-get -q update && apt-get -qyV install \
                    g++ make git libssl-dev pkg-config curl &&\
                $NODE_SRC_PATH/configure &&\
                make --quiet -C $NODE_SRC_PATH &&\
                make --quiet -C $NODE_SRC_PATH install &&\
                wget -q -O - https://npmjs.org/install.sh | clean=no sh &&\
                npm install -g log.io --user "root" &&\
                apt-get -qyV remove g++ make libssl-dev pkg-config &&\
                apt-get -qyV autoremove &&\
                rm -rf /var/lib/apt/lists/* &&\
                apt-get clean

# Process startup info
ENV             SPOKE_NAME logio

COPY            /web_server.conf /tmp/web_server.conf
COPY            /entrypoint.sh /entrypoint.sh

# For Spoke-detach mode
WORKDIR         /root
RUN             git config --global user.email "radial@brianclements.net" &&\
                git config --global user.name "radial"

EXPOSE          28777
EXPOSE          28778
