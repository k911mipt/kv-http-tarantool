#!/usr/bin/env tarantool
local kv_store = require("store.kv")
local web_server = require("web.server")
local web_limiter = require("web.limiter")

box.cfg {
    -- log = './log.log',

    -- listen = 3301,
    -- background = true,
    -- log = '1.log',
    -- pid_file = '1.pid'
}

--starting database
kv_store:start()
--initializing web server with database
web_server:init(kv_store)
--setting a new requests-per-second limiter 
web_server:set_limiter(60, web_limiter)
--starting a web server
web_server:start()