local function too_many_requests(req)
    local resp = req:render({json = {error = "Too many requests. Try again later"}})
    resp.status = 429
    return resp
end

local new = function(capacity)
    local self = {
        capacity = capacity,
        second = os.time(),
        count = 0,
        check_query_rate = function(self)
            return function(req)
                local second = os.time()
                if second ~= self.second then
                    self.second = second
                    self.count = 1
                    return req:next()
                end
                if self.count < capacity then
                    self.count = self.count + 1
                    return req:next()
                end
                return too_many_requests(req)
            end
        end
    }
    return self:check_query_rate()
end

return {
    new = new
}
