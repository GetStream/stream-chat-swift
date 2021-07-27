---
title: Controllers Overview
---

The `StreamChat` framework ships with controllers and delegates that you can use to build your own views.

Each controller exposes API functionality and supports delegation, controllers their delegates are documented here based on the kind of data they control and allow you to observe. You can find examples on how to build your own view as well.

## Using Controllers

Controllers expose functionality via event subscriptions and API calls. In most cases you need to call the `synchronize` method on your controller instance. This is done to 
avoid side-effects from initialization and to make sure that the controller is ready to be used.

ie. a channel controller needs to watch a channel before it's delegate can receive calls.

It's a best practice to pass synchronize a completion block to handle error cases. However, error handling is optional and you can use synchronize as a fire and forget method.

```swift
    /// ...
    controller.synchronize { error in
        /// something did not work with the controller setup
        if error != nil {
            log.assertionFailure(error!)
            return
        }
    }
    /// ...
```
