---
title: EventsControllerDelegate
---

`EventsController` uses this protocol to communicate events to the delegate.

``` swift
public protocol EventsControllerDelegate: AnyObject 
```

## Inheritance

`AnyObject`

## Requirements

### eventsController(\_:​didReceiveEvent:​)

The method is invoked when an event is observed.

``` swift
func eventsController(_ controller: EventsController, didReceiveEvent event: Event)
```

#### Parameters

  - controller: The events controller listening for the events.
  - event: The observed event.
