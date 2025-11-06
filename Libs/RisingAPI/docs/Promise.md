# Promise

RisingAPI uses so-called *promises* to wrap API responses. For a detailed guide on how to work with promises, please refer to external resources like this guide to [Promises in JavaScript](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_promises).

The implementation used for this API is available via `LibStub("deferred")` and closely follows the [JavaScript implementation](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise). A notable exception is the name of the method to chain promises `promise.then(...)`. Given that `then` is a reserved keyword in Lua, the method is instead named `promise:next(...)`. Additionally, the behaviour might differ from JavaScript regarding when callbacks are executed (e.g. `AllSettled()` if all promises are already settled). For details, please refer to the implementation.

#### Basic usage example
```lua
local API = LibStub("RisingAPI")

API.Transmog.GetBalance():next(function(result)
	print("Your transmog shard balance is: " .. result.shards)
end):catch(function(err)
	print("An error occured: " .. err.message)
end)
```

#### Reference overview
* Import library `local Promise = LibStub("deferred")`
* Create a new promise `local p = Promise.New()` (differs from JavaScript)
* Resolve promise `p:resolve(value)`
* Reject promise `p:reject(error)`
* Handle result `p:next(successHandler, errorHandler)` (same as `p.then(...)` in JavaScript)
* Handle error `p:catch(errorHandler)`
* Execute a handler unconditionally `p:finally(handler)` (no parameter is passed to `handler`)
* Create an already settled promise `Promise.Resolved(value)` or `Promise.Rejected(err)`
* Working with multiple promises:
	* Wait for multiple promises to settle
	  ```lua
	  Promise.All({ p1, p2, p3, ... }):next(function(results)
	      -- results == { r1, r2, r3, ... }
	  end):catch(function(firstError)
	      -- handle error
	  end)
	  ```
	  When any of the promises (`p1`, ...) is rejected with an error, the resulting promise is immediately rejected with the same error.
	  
	  If you instead want to wait for all promises to settle, use `Promise.AllSettled({ p1, ... })` which results in an array whose entries are either `{ status = "fulfilled", value = value }` or `{ status = "rejected", reason = errorMessage }`.
	* `Promise.Race({ p1, ... })` return a promise that settles as soon as any one of the given promises settles with the result of that promise (success or failure).
	* `Promise.Any({ p1, ... })` return a promise that is resolved as soon as any one of the given promises is resolved (with the value of that promise) or rejected once all promises are rejected (with an array containing all errors).

Refer to the [JavaScript documentation](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise) for more details on the above methods.