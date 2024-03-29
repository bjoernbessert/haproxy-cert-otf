ARG UBUNTU_DOCKER_IMAGE
FROM $UBUNTU_DOCKER_IMAGE

ARG HAPROXY_MAIN_VERSION

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -yq tzdata
RUN echo Europe/Berlin >/etc/timezone && \
    ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

RUN apt-get update && apt-get install -yq software-properties-common

#START MARKER1
RUN add-apt-repository -y ppa:vbernat/haproxy-$HAPROXY_MAIN_VERSION && apt-get update && \
    apt-get install -yq haproxy=$HAPROXY_MAIN_VERSION.\* 
#END MARKER1

RUN apt-get install -yq lua-socket openssl

# silencing a not critical openssl warning/error
# Can't load /root/.rnd into RNG
# 139879202243008:error:2406F079:random number generator:RAND_load_file:Cannot open file:../crypto/rand/randfile.c:88:Filename=/root/.rnd
RUN touch /root/.rnd

RUN apt-get update && apt-get install -yq supervisor
RUN mkdir -p /var/log/supervisor
COPY files/supervisord.conf /etc/supervisor/supervisord.conf

RUN apt-get update && apt-get install -yq netcat socat iputils-ping curl wget less vim psmisc net-tools

COPY files/generate-cert /opt/generate-cert

RUN mkdir /etc/haproxy/certs
COPY files/fallback.example.local.pem /etc/haproxy/certs/

RUN mkdir /etc/haproxy/lua_files
RUN rm -f /etc/haproxy/haproxy.cfg
COPY files/haproxy.cfg  /etc/haproxy/haproxy.cfg

# For local testing
COPY files/generate-cert/ca.crt /usr/local/share/ca-certificates/
RUN update-ca-certificates

# Info
RUN haproxy -vv


CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
