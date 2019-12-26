FROM tarantool/tarantool:2.2
MAINTAINER doc@tarantool.org

COPY *.lua /opt/tarantool/
COPY /store/ /opt/tarantool/store/
COPY ./web/. /opt/tarantool/web/

# installing tarantool htpp-server that supports middleware
RUN set -x \
    && apk add --no-cache --virtual .build-deps \
        git \
        cmake \
        make \
        gcc \
        g++ \
    && cd /opt/tarantool/ \
    && tarantoolctl rocks install http 2.0.1-1\
    && : "---------- remove build deps ----------" \
    && apk del .build-deps

EXPOSE 8080
WORKDIR /opt/tarantool

CMD ["tarantool", "main.lua"]
