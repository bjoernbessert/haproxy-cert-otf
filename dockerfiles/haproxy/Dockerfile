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

ENV HAPROXY_GIT_URL "https://github.com/haproxy/haproxy.git"

RUN set -x \
        \
        && apt-get update && apt-get install -y --no-install-recommends \
                ca-certificates \
                gcc \
                libc6-dev \
                liblua5.3-dev \
                libpcre2-dev \
                libssl-dev \
                make \
                zlib1g-dev \
                git-core \
        && cd /usr/src \
        && git clone "$HAPROXY_GIT_URL" haproxy \
        \
        && makeOpts=' \
                PREFIX=/usr \
                TARGET=linux-glibc \
                USE_GETADDRINFO=1 \
                USE_LUA=1 LUA_INC=/usr/include/lua5.3 \
                USE_OPENSSL=1 \
                USE_PCRE2=1 USE_PCRE2_JIT=1 \
                USE_ZLIB=1 \
                \
                EXTRA_OBJS="contrib/prometheus-exporter/service-prometheus.o" \
        ' \
        && nproc="$(nproc)" \
        && eval "make -C /usr/src/haproxy -j '$nproc' all $makeOpts" \
        && eval "make -C /usr/src/haproxy install-bin $makeOpts" \
        \
        && mkdir -p /etc/haproxy \
        && cp -R /usr/src/haproxy/examples/errorfiles /etc/haproxy/errors \
        && rm -rf /usr/src/haproxy

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
COPY files/haproxy_front.cfg /etc/haproxy/haproxy_front.cfg
COPY files/haproxy_back.cfg  /etc/haproxy/haproxy_back.cfg

# For local testing
COPY files/generate-cert/ca.crt /usr/local/share/ca-certificates/
RUN update-ca-certificates

# Info
RUN haproxy -vv


CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]

