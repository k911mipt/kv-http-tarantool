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

If requests number per second exceeds specified limit, an error `429` is returned

Every operation is logged via default tarantool logger

