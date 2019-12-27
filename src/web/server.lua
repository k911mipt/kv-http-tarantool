local log = require("log")
local json = require("json")
local web_handlers = require("web.handlers")
local http_router = require("http.router")
local http_server = require("http.server")

local httpd = {
    init = function(self, store)
        local handlers = web_handlers.new(store)
        local router = http_router.new()
            :route( -- health check
                {method = "GET", path = "/"}, 
                function (req)
                    return {status = 200, body = json.encode({result = "OK", capacity = self.capacity})}
                end
            )
            :route({method = "POST", path = "/kv"}, handlers:add())
            :route({method = "PUT", path = "/kv/:id"}, handlers:change())
            :route({method = "GET", path = "/kv/:id"}, handlers:get())
            :route({method = "DELETE", path = "/kv/:id"}, handlers:delete())
        local PORT = os.getenv('PORT')
        self.server = http_server.new("0.0.0.0", PORT)
        self.router = router
        self.server:set_router(router)
        self.capacity = 0
    end,
    set_limiter = function(self, capacity, limiter)
        self.capacity = capacity
        local ok = self.router:use(limiter.new(capacity), {
            preroute = true,
            name = "query frequency limiter",
            method = "ANY",
            path = "*",
        })
        assert(ok, 'no conflict on adding query frequency limiter')
    end,
    start = function(self)
        self.server:start()
        log.info("Started http server service")
    end
}
return httpd
