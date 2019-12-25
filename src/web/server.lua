local log = require("log")

local function check_query_rate(req)
    print("called middleware")
    -- TODO put limiter logic here
    return req:next()
end

local httpd = {
    init = function(self, store)
        local handlers = require("web.handlers").new(store)
        local router = require("http.router").new()
            :route( -- health check
                {method = "GET", path = "/"}, 
                function (req)
                    return {status = 200, body = "OK"}
                end
            )
            :route({method = "POST", path = "/kv"}, handlers:add())
            :route({method = "PUT", path = "/kv/:id"}, handlers:change())
            :route({method = "GET", path = "/kv/:id"}, handlers:get())
            :route({method = "DELETE", path = "/kv/:id"}, handlers:delete())
        local ok = router:use(check_query_rate, {
            preroute = true,
            name = "query frequency limiter",
            method = "ANY",
            path = "/.*",
        })
        assert(ok, 'no conflict on adding query frequency limiter')
        
        self.server = require("http.server").new(nil, 8080)
        self.server:set_router(router)
    end,
    start = function(self)
        self.server:start()
        log.info("Started http server service")
    end
}
return httpd
