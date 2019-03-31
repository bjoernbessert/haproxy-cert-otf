FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -yq tzdata
RUN echo Europe/Berlin >/etc/timezone && \
    ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

RUN apt-get update && apt-get install -yq software-properties-common

#RUN add-apt-repository -y ppa:vbernat/haproxy-1.8 && apt-get update && \
#    apt-get install -yq haproxy=1.8.\* 
RUN add-apt-repository -y ppa:vbernat/haproxy-1.9 && apt-get update && \
    apt-get install -yq haproxy=1.9.\* 

RUN apt-get install -yq lua-socket openssl

RUN apt-get update && apt-get install -yq supervisor
RUN mkdir -p /var/log/supervisor
COPY files/supervisord.conf /etc/supervisor/supervisord.conf

RUN apt-get update && apt-get install -yq netcat socat iputils-ping curl wget less vim psmisc net-tools

COPY files/generate-cert /opt/generate-cert

RUN mkdir /etc/haproxy/certs
COPY files/fallback.example.local.pem /etc/haproxy/certs/

RUN mkdir /etc/haproxy/lua_files
RUN rm -f /etc/haproxy/haproxy.cfg
COPY files/haproxy_front.cfg /etc/haproxy/haproxy_front.cfg
COPY files/haproxy_back.cfg  /etc/haproxy/haproxy_back.cfg

# For local testing
COPY files/generate-cert/ca.crt /usr/local/share/ca-certificates/
RUN update-ca-certificates

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
