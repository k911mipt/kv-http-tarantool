local json = require("json")
local clock = require("clock")
local fiber = require("fiber")
local tap = require("tap")
local http_client = require("http.client")
local HOST = "http://localhost:8080/"
local URI = HOST.."kv/"

local taptest = tap.test("test-name")

taptest:diag("Started testing kv store via http requests")

local function new_test_func(metadata)
    return function(taptest)
        local id = metadata.id
        local uri = URI
        if id ~= "" then
            uri = uri .. id .. "/"
        end

        fiber.sleep(1)

        local resp = http_client.request(metadata.method, uri, metadata.body)
        taptest:plan(2)
        taptest:is(resp.status, metadata.expected_status)
        taptest:is(resp.body, metadata.expected_body)
    end
end

local function request_limiter_test(taptest)
    taptest:diag("Request limiter test")
    -- taptest:plan(4)

    local resp = http_client.get(HOST)
    local is_parsed, obj = pcall(function() return json.decode(resp.body) end)
    taptest:is(is_parsed, true, "has got host/ reponse")
    if not is_parsed then
        return
    end

    local capacity = obj.capacity
    taptest:isnt(capacity, nil, "has limiter set")
    if capacity == nil then
        return
    end

    taptest:diag("Exceed frequency")

    fiber.sleep(1)
    local time_start = clock.monotonic64()
    -- there is a primitive requests rate limiter, which only guarantees not exceeding x2 capacity,
    -- so checking x2 + 1 requests
    for i = 1, capacity * 2 + 1 do
        resp = http_client.get(HOST)
    end
    local time_end = clock.monotonic64()

    if time_end - time_start < 1000000000 then -- succeeded to perform all requests in less than a second
        taptest:is(resp.body, json.encode({error = "Too many requests. Try again later"}, "has rejected too frequent requests"))
    else
        taptest:diag("Cannot perform required requests amount in a second to ensure that superior number would be rejected")
    end
    taptest:diag("Deceed frequency")
    fiber.sleep(1)
    time_start = clock.monotonic64()
    -- there is a primitive requests rate limiter, which only guarantees not exceeding x2 capacity,
    -- so checking x2 + 1 requests
    for i = 1, capacity do
        resp = http_client.get(HOST)
    end
    time_end = clock.monotonic64()
    taptest:isnt(resp.error, json.encode({error = "Too many requests. Try again later"}, "has passed suitable requests frequency"))
end

local test_id = "__test_id1"
local test_insert_val = {val = "val"}
local test_insert_val_json = json.encode({val = "val"})
local test_insert_body_json = json.encode({key = test_id, value = test_insert_val})
local test_update_val_json = json.encode({upd_val = "upd_val"})
local tests = {
    {
        name = "check insert",
        metadata = {
            method = "POST",
            id = "",
            body = test_insert_body_json,
            expected_status = 201,
            expected_body = "Created"
        }
    },
    {
        name = "check insert 'duplicate' error",
        metadata = {
            method = "POST",
            id = "",
            body = test_insert_body_json,
            expected_status = 409,
            expected_body = json.encode({error = "key '" .. test_id .. "' already exists"})
        }
    },
    {
        name = "check get",
        metadata = {
            method = "GET",
            id = test_id,
            expected_status = 200,
            expected_body = test_insert_val_json
        }
    },
    {
        name = "check update",
        metadata = {
            method = "PUT",
            id = test_id,
            body = test_update_val_json,
            expected_status = 200,
            expected_body = "OK"
        }
    },
    {
        name = "check get after update",
        metadata = {
            method = "GET",
            id = test_id,
            expected_status = 200,
            expected_body = test_update_val_json
        }
    },
    {
        name = "check update 'invalid_body' error",
        metadata = {
            method = "PUT",
            id = test_id,
            body = "some_body",
            expected_status = 400,
            expected_body = json.encode({error = "Invalid body: cannot parse json"})
        }
    },
    {
        name = "check delete",
        metadata = {
            method = "DELETE",
            id = test_id,
            expected_status = 200,
            expected_body = "OK"
        }
    },
    {
        name = "check get 'not found' error",
        metadata = {
            method = "GET",
            id = test_id,
            expected_status = 404,
            expected_body = json.encode({error = "key '" .. test_id .. "' not found"})
        }
    },
    {
        name = "check update 'not found' error",
        metadata = {
            method = "PUT",
            id = test_id,
            body = test_insert_val_json,
            expected_status = 404,
            expected_body = json.encode({error = "key '" .. test_id .. "' not found"})
        }
    },
    {
        name = "check delete 'not found' error",
        metadata = {
            method = "DELETE",
            id = test_id,
            expected_status = 404,
            expected_body = json.encode({error = "key '" .. test_id .. "' not found"})
        }
    },
    {
        name = "check insert 'invalid_body' error",
        metadata = {
            method = "POST",
            id = "",
            body = "some_body",
            expected_status = 400,
            expected_body = json.encode({error = "Invalid body: cannot parse json"})
        }
    },
    {
        name = "check insert 'invalid_data' error",
        metadata = {
            method = "POST",
            id = "",
            body = json.encode({key = {}}),
            expected_status = 400,
            expected_body = json.encode({error = "Invalid data: missing 'key' or 'value'"})
        }
    }
}

local num_tests = table.getn(tests)
taptest:plan(num_tests + 4) -- 4 request rate limiting tests
for i = 1, num_tests do
    taptest:test(tests[i].name, new_test_func(tests[i].metadata))
end

request_limiter_test(taptest)

taptest:check()