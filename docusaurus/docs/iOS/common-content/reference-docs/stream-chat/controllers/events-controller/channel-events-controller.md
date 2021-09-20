---
title: ChannelEventsController
---

`ChannelEventsController` is a controller class which allows to observe channel
events and send custom events.

``` swift
public class ChannelEventsController: EventsController 
```

## Inheritance

[`EventsController`](../events-controller)

## Properties

### `cid`

``` swift
public var cid: ChannelId? 
```

## Methods

### `sendEvent(_:completion:)`

Sends a custom event to the channel with `cid`.

``` swift
public func sendEvent<T: CustomEventPayload>(_ payload: T, completion: ((Error?) -> Void)? = nil) 
```

#### Parameters

  - payload: A custom event payload to be sent.
  - completion: A completion.
