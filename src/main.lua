#!/usr/bin/env tarantool
local kv_store = require("store.kv")
local http_server = require("web.server")

box.cfg {
    -- log = './log.log',

    -- listen = 3301,
    -- background = true,
    -- log = '1.log',
    -- pid_file = '1.pid'

}

kv_store:start()

http_server:init(kv_store)
http_server:start()