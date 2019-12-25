local log = require("log")

-- unpack value from kv pair
local function unpack(pair)
    return pair[1][2]
end

local kv = {
    -- init storage
    start = function(self)
        space_name = "kv"
        box.once(
            "init",
            function()
                s = box.schema.space.create(space_name)
                s:format(
                    {
                        {name = "key", type = "string"},
                        {name = "value"}
                    }
                )
                s:create_index(
                    "primary",
                    {
                        type = "hash",
                        parts = {"key"}
                    }
                )
                box.schema.user.grant("guest", "read,write,execute", "universe")
            end
        )
        self.space = box.space[space_name]
        log.info("Started database service")
        return true
    end,
    -- check if storage has value with certain key
    has = function(self, key)
        local value = self.space:select({key})
        return (value ~= nil and next(value) ~= nil)
    end,
    -- get value by a key
    select = function(self, key)
        local pair = self.space:select({key})
        log.info("selected value at key:'%s'", key)
        if next(pair) == nil then
            return nil
        end
        return unpack(pair)
    end,
    -- insert a key-value pair
    insert = function(self, key, value)
        self.space:insert({key, value})
        log.info("inserted value at key:'%s'", key)
        return true
    end,
    -- update a value at key
    update = function(self, key, value)
        self.space:replace({key, value})
        log.info("updated value at key:'%s'", key)
        return true
    end,
    -- delete value by key
    drop = function(self, key)
        self.space:delete({key})
        log.info("deleted value at key:'%s'", key)
        return true
    end
}

return kv
