# ------------------------------------------------------------------------------
# Custom Nginx Image
#
# This image is based on Alpine Linux and performs the following steps:
#   1. Sets environment variables for NGINX and module versions, and defines module URLs.
#   2. Installs build dependencies and clones necessary module repositories.
#   3. Downloads, verifies (using GPG), and compiles NGINX with additional modules.
#   4. Configures the runtime environment with required modules and log redirection.
# ------------------------------------------------------------------------------
FROM alpine:3.21

WORKDIR /var/www/html

ENV NGINX_VERSION=1.27.4
ENV MORE_SET_HEADER_VERSION=0.38
ENV FANCYINDEX=0.5.2
ENV MODULE_URL_BASE=https://nginx.org/packages/alpine/v3.21/main/x86_64/

RUN mkdir -p /var/www/html \
    # && GPG_KEYS=D6786CE303D9A9022998DC6CC8464D549AF75C0A \
    && CONFIG="\
        --prefix=/etc/nginx \
        --sbin-path=/usr/sbin/nginx \
        --modules-path=/usr/lib/nginx/modules \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/run/nginx.lock \
        --http-client-body-temp-path=/var/cache/nginx/client_temp \
        --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
        --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
        --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
        --user=nginx \
        --group=nginx \
        --with-http_ssl_module \
        --with-http_realip_module \
        --with-http_addition_module \
        --with-http_sub_module \
        --with-http_dav_module \
        --with-http_flv_module \
        --with-http_mp4_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_random_index_module \
        --with-http_secure_link_module \
        --with-http_stub_status_module \
        --with-http_auth_request_module \
        --with-http_xslt_module=dynamic \
        --with-http_image_filter_module=dynamic \
        --with-http_geoip_module=dynamic \
        --with-threads \
        --with-stream \
        --with-stream_ssl_module \
        --with-stream_ssl_preread_module \
        --with-stream_realip_module \
        --with-stream_geoip_module=dynamic \
        --with-http_slice_module \
        --with-mail \
        --with-mail_ssl_module \
        --with-compat \
        --with-file-aio \
        --with-http_v2_module \
        --add-module=/tmp/headers-more-nginx-module-$MORE_SET_HEADER_VERSION \
        --add-module=/tmp/ngx-fancyindex-$FANCYINDEX \
        --add-module=/tmp/ngx_http_substitutions_filter_module \
        --add-module=/tmp/ngx_http_geoip2_module \
        --add-module=/tmp/nginx-rtmp-module \
        --add-module=/tmp/lua-nginx-module \
    " \
    && addgroup -S nginx \
    && adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx \
    && apk add --no-cache --allow-untrusted --virtual .build-deps \
        git \
        gcc \
        libc-dev \
        make \
        openssl-dev \
        pcre-dev \
        zlib-dev \
        linux-headers \
        curl \
        gnupg \
        libxslt-dev \
        gd-dev \
        geoip-dev \
        libmaxminddb-dev \
        luajit-dev \
    && cd /tmp/ \
    # Clone required module repositories
    && git clone https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git /tmp/ngx_http_substitutions_filter_module \
    && git clone https://github.com/leev/ngx_http_geoip2_module.git /tmp/ngx_http_geoip2_module \
    && git clone https://github.com/arut/nginx-rtmp-module.git /tmp/nginx-rtmp-module \
    && git clone https://github.com/openresty/lua-nginx-module.git /tmp/lua-nginx-module \
     && curl -sfSL https://github.com/openresty/headers-more-nginx-module/archive/v$MORE_SET_HEADER_VERSION.tar.gz -o $MORE_SET_HEADER_VERSION.tar.gz \
    && tar xvf $MORE_SET_HEADER_VERSION.tar.gz \
    && curl -sfSL https://github.com/aperezdc/ngx-fancyindex/releases/download/v$FANCYINDEX/ngx-fancyindex-$FANCYINDEX.tar.xz -o fancyindex.tar.xz \
    && tar xvf fancyindex.tar.xz \
    && curl -sfSL https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o nginx.tar.gz \
    && mkdir -p /usr/src \
    && tar -zxC /usr/src -f nginx.tar.gz \
    && rm nginx.tar.gz \
    && cd /usr/src/nginx-$NGINX_VERSION \
    && export LUAJIT_LIB=/usr/lib \
    && export LUAJIT_INC=/usr/include/luajit-2.1 \
    && ./configure $CONFIG --with-debug \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && mv objs/nginx objs/nginx-debug \
    && mv objs/ngx_http_xslt_filter_module.so objs/ngx_http_xslt_filter_module-debug.so \
    && mv objs/ngx_http_image_filter_module.so objs/ngx_http_image_filter_module-debug.so \
    && mv objs/ngx_http_geoip_module.so objs/ngx_http_geoip_module-debug.so \
    && mv objs/ngx_stream_geoip_module.so objs/ngx_stream_geoip_module-debug.so \
    && ./configure $CONFIG \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && make install \
    && rm -rf /etc/nginx/html/ \
    && mkdir /etc/nginx/conf.d/ \
    && mkdir -p /usr/share/nginx/html/ \
    && install -m644 html/index.html /usr/share/nginx/html/ \
    && install -m644 html/50x.html /usr/share/nginx/html/ \
    && install -m755 objs/nginx-debug /usr/sbin/nginx-debug \
    && install -m755 objs/ngx_http_xslt_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_xslt_filter_module-debug.so \
    && install -m755 objs/ngx_http_image_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_image_filter_module-debug.so \
    && install -m755 objs/ngx_http_geoip_module-debug.so /usr/lib/nginx/modules/ngx_http_geoip_module-debug.so \
    && install -m755 objs/ngx_stream_geoip_module-debug.so /usr/lib/nginx/modules/ngx_stream_geoip_module-debug.so \
    && ln -s ../../usr/lib/nginx/modules /etc/nginx/modules \
    && strip /usr/sbin/nginx* \
    && strip /usr/lib/nginx/modules/*.so \
    && rm -rf /usr/src/nginx-$NGINX_VERSION \
    \
    # Install gettext for environment variable substitution
    && apk add --no-cache --virtual .gettext gettext \
    && mv /usr/bin/envsubst /tmp/ \
    \
    && runDeps="$( \
        scanelf --needed --nobanner /usr/sbin/nginx /usr/lib/nginx/modules/*.so /tmp/envsubst \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | sort -u \
            | xargs -r apk info --installed \
            | sort -u \
    )" \
    && apk add --no-cache --virtual .nginx-rundeps $runDeps apache2-utils \
    c-ares \
    libstdc++ \
    curl \
    libmaxminddb \
    luajit \
    && apk del --no-cache .build-deps \
    && apk del --no-cache .gettext \
    && mv /tmp/envsubst /usr/local/bin/ \
    && rm /tmp/$MORE_SET_HEADER_VERSION.tar.gz \
    && rm -rf /tmp/headers-more-nginx-module-$MORE_SET_HEADER_VERSION \
    && rm /tmp/fancyindex.tar.xz \
    && rm -rf /tmp/ngx-fancyindex-$FANCYINDEX \
    && rm -rf /tmp/ngx_http_substitutions_filter_module \
    && rm -rf /tmp/pear \
    \
    # Redirect logs to Docker logging collector
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && cp /usr/share/nginx/html/* /var/www/html

# Copy Nginx configuration files
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY conf/nginx.default.conf /etc/nginx/conf.d/default.conf

# Download and install the OTEL module then clean up apk artifacts
RUN wget -qO- $MODULE_URL_BASE | \
    grep -o 'nginx-module-otel-[0-9\.]*-r[0-9]*\.apk' | \
    sort -Vr | \
    head -n 1 | \
    xargs -I {} wget ${MODULE_URL_BASE}{} && \
    tar -xzf ./nginx-module-otel-*.apk 
RUN install -m755 /var/www/html/usr/lib/nginx/modules/ngx_otel_module.so /etc/nginx/modules/ngx_otel_module.so && \
    rm nginx-module-otel-*.apk

# Copy the update script and set execution permissions
COPY scripts/geolite2.cron /usr/local/bin/geolite2.cron
COPY scripts/geolite2.sh /usr/local/bin/geolite2.sh
RUN chmod +x /usr/local/bin/geolite2.sh

EXPOSE 80 443
STOPSIGNAL SIGQUIT

# Copy the entrypoint script and set execution permissions
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set the entrypoint to process dynamic environment variables in the configuration
ENTRYPOINT ["/entrypoint.sh"]

CMD ["nginx", "-g", "daemon off;"]
