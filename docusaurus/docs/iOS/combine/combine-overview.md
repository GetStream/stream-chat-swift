---
title: Overview
---

The `StreamChat` framework ships with controllers that are fully compatible with `Combine`.
You can use these combine-compatible controllers to observe the changes to the controllers, and build your own views to consume the data.

Each controller exposes publishers based on the kind of data they control and allow you to observe changes. You can find examples on how to build your own views using these publishers here.

## Using the `Combine` extensions of Controllers

When using combine extensions of the controllers, you need to call the `synchronize` method on your controller instance before starting to observe the publishers.
This is done to avoid the side-effects from initialization and to make sure that the controller is ready to be used.

i.e. a channel controller needs to watch a channel before its publisher can emit changes.

It's a best practice to pass the synchronize a completion block to handle error cases. However, error handling is optional, and you can use synchronize as a fire and forget method.

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
