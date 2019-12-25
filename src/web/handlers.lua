local log = require("log")
local json = require("json")


local function invalid_body_resp(req, msg)
    local resp = req:render({json = {request = req:method()..' '..req:path(),error = "Invalid body: "..msg}})
    resp.status = 400
    return resp
end

local function invalid_data_resp(req, msg)
    local resp = req:render({json = { request = req:method()..' '..req:path(), error = "Invalid data: "..msg }})
    resp.status = 400
    return resp
end

local function duplicate_key_resp(req, msg)
    local resp = req:render({json = { request = req:method()..' '..req:path(), error = "key '"..msg.."' already exists" }})
    resp.status = 409
    return resp
end

local function key_not_found(req, key)
    local resp = req:render({json = {request = req:method()..' '..req:path(),error = "key '"..key.."' not found"}})
    resp.status = 404
    return resp
end

local function pass_parsed_json(processer)
    return function(req)
        local is_parsed, obj = pcall(function() return req:json() end)
        if not is_parsed then
            return invalid_body_resp(req, "cannot parse json")
        end
        return processer(req, obj)
    end
end

local new = function(store)
    local self = {
        store = store,

        check_exist_pass = function(self, processer)
            return function(req, value)
                local key = req:stash("id")
                if (self.store:has(key) == false) then
                    return key_not_found(req, key)
                end
                return processer(req, key, value)
            end
        end,

        insert = function(self, req)
            return function(req, obj)
                local key, value = obj["key"], obj["value"]
                if (key == nil) or (type(key) ~= "string") or (value == nil) then
                    return invalid_data_resp(req, "missing 'key' or 'value'")
                end
                if (self.store:has(key)) then
                    log.info("insert value at '"..key.."' failed: duplicate")
                    return duplicate_key_resp(req, key)
                end
                self.store:insert(key, value)
                return {status = 201, body = "Created"}
            end
        end,
        select = function(self, req)
            return function(req, key)
                local value = self.store:select(key)
                return { status = 200, body = json.encode(value) }
            end
        end,
        update = function(self, req)
            return function(req, key, value)
                self.store:update(key, value)
                return { status = 200, body = "OK" }
            end
        end,
        drop = function(self, req)
            return function(req, key, value)
                self.store:drop(key)
                return { status = 200, body = "OK" }
            end
        end,

        add = function(self) return pass_parsed_json(self:insert()) end,
        change = function(self) return pass_parsed_json(self:check_exist_pass(self:update())) end,
        get = function(self) return self:check_exist_pass(self:select()) end,
        delete = function(self) return self:check_exist_pass(self:drop()) end
    }
    return self
end

return {
    new = new
}
