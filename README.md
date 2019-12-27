# Key-Value storage using [Tarantool platform](https://www.tarantool.io/)

## API

* Insert key-value pair  
  `POST /kv body: {key: "test", "value": {SOME ARBITRARY JSON}}`  
  Returns:
  * 201 : success
  * 400 : invalid body
  * 409 : key already exists
* Update value at key  
  `PUT /kv/key body: {"value": {SOME ARBITRARY JSON}}`  
  Returns:
  * 200 : success
  * 400 : invalid body
  * 404 : key not found
* Retrive value at key  
  `GET /kv/key`  
  Returns:
  * 200 : success
  * 404 : key not found
* Drop key-value pair  
  `DELETE /kv/key`  
  Returns:
  * 200 : success
  * 404 : key not found

If requests number per second exceeds specified limit, an error `429` is returned.
> Note: limiter is quite simple so it's actually possible to exceed limit as twice as set limit.


Every operation is logged via default tarantool logger


## Docker build && test && run

```docker
docker-compose build
docker-compose up # <- this will also run tests
```

## Demonstration

Application deployed on http://gentle-springs-29037.herokuapp.com/

You can test storage with following curl commands
```bash

# Create pair `mykey` - `{"myvalue": "a"}`
curl --location --request POST 'http://gentle-springs-29037.herokuapp.com/kv/' \
--header 'Content-Type: application/json' \
--data-raw '{
    "key": "mykey",
    "value": {
        "myvalue": "a"
    }
}'

# Get pair by id `mykey`
curl --location --request GET 'https://gentle-springs-29037.herokuapp.com/kv/mykey/' \
--header 'Content-Type: application/json' \
--data-raw ''

# Update pair `mykey` with `"my_new_value": {"a": "b"}`
curl --location --request PUT 'https://gentle-springs-29037.herokuapp.com/kv/mykey/' \
--header 'Content-Type: application/json' \
--data-raw '{
    "my_new_value": {
        "a": "b"
    }
}'

# Drop pair by id `mykey`
curl --location --request DELETE 'https://gentle-springs-29037.herokuapp.com/kv/mykey/' \
--header 'Content-Type: application/json' \
--data-raw ''
```