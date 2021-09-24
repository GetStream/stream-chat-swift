---
title: EventsController.ObservableObject
---

A wrapper object for `UserListController` type which makes it possible to use the controller comfortably in SwiftUI.

``` swift
public class ObservableObject: SwiftUI.ObservableObject 
```

## Inheritance

[`EventsControllerDelegate`](../events-controller-delegate), `SwiftUI.ObservableObject`

## Properties

### `controller`

The underlying controller. You can still access it and call methods on it.

``` swift
public let controller: EventsController
```

### `mostRecentEvent`

The last observed event.

``` swift
@Published public private(set) var mostRecentEvent: Event?
```

## Methods

### `eventsController(_:didReceiveEvent:)`

``` swift
public func eventsController(
        _ controller: EventsController,
        didReceiveEvent event: Event
    ) 
```
