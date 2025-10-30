ARG ALPINE_VERSION=3.20

##### Build nginx with RTMP support #####
FROM alpine:${ALPINE_VERSION} AS builder
LABEL maintainer="7YHong <https://blog.qiyanghong.cn>"

ARG NGINX_VERSION=1.26.2
ARG NGINX_RTMP_MODULE_VERSION=1.2.2

RUN apk add --no-cache \
        bash \
        build-base \
        ca-certificates \
        freetype-dev \
        gcc \
        lame-dev \
        libgcc \
        libc-dev \
        libtheora-dev \
        libvorbis-dev \
        libvpx-dev \
        linux-headers \
        make \
        musl-dev \
        openssl \
        openssl-dev \
        pcre \
        pcre-dev \
        pkgconf \
        rtmpdump-dev \
        wget \
        yasm \
        zlib-dev

RUN mkdir -p /tmp/build && \
    cd /tmp/build && \
    wget -q https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar zxf nginx-${NGINX_VERSION}.tar.gz

RUN cd /tmp/build && \
    wget -q -O nginx-rtmp-module.tar.gz https://github.com/arut/nginx-rtmp-module/archive/refs/tags/v${NGINX_RTMP_MODULE_VERSION}.tar.gz && \
    tar zxf nginx-rtmp-module.tar.gz

RUN cd /tmp/build/nginx-${NGINX_VERSION} && \
    ./configure \
        --sbin-path=/usr/local/sbin/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx/nginx.pid \
        --lock-path=/var/lock/nginx.lock \
        --http-client-body-temp-path=/tmp/nginx-client-body \
        --with-http_ssl_module \
        --with-threads \
        --add-module=/tmp/build/nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION} && \
    make CFLAGS=-Wno-error -j "$(getconf _NPROCESSORS_ONLN)" && \
    make install

RUN cp /tmp/build/nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION}/stat.xsl /usr/local/nginx/html/stat.xsl && \
    rm -rf /tmp/build

##### Runtime image with Flask manager #####
FROM alpine:${ALPINE_VERSION}

ENV PATH="/opt/rtmp-manager/.venv/bin:/usr/local/sbin:${PATH}"

RUN apk add --no-cache \
        bash \
        pcre \
        python3 \
        py3-pip \
        supervisor

COPY --from=builder /usr/local /usr/local
COPY --from=builder /etc/nginx /etc/nginx
COPY --from=builder /var/log/nginx /var/log/nginx
COPY --from=builder /var/lock /var/lock
COPY --from=builder /var/run/nginx /var/run/nginx

RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

COPY nginx.conf /etc/nginx/nginx.conf
COPY nginx.d/rtmp_pushes.conf /etc/nginx/conf.d/rtmp_pushes.conf

RUN mkdir -p /opt/rtmp-manager /var/lib/nginx-manager && \
    chmod 755 /opt/rtmp-manager

COPY manager/ /opt/rtmp-manager/
COPY supervisord.conf /etc/supervisord.conf

RUN python3 -m venv /opt/rtmp-manager/.venv && \
    /opt/rtmp-manager/.venv/bin/pip install --no-cache-dir \
        Flask==3.0.3 \
        gunicorn==21.2.0

EXPOSE 1935 8080 5000

CMD ["supervisord", "-c", "/etc/supervisord.conf"]
