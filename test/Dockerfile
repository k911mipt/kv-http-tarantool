FROM tarantool/tarantool:2.2
MAINTAINER doc@tarantool.org

COPY *.lua /opt/tarantool/
EXPOSE 8080
WORKDIR /opt/tarantool

CMD ["tarantool", "test.lua"]
