---
title: CustomEventPayload
---

A protocol custom event payload must conform to.

``` swift
public protocol CustomEventPayload: Codable, Hashable 
```

## Inheritance

`Codable`, `Hashable`

## Requirements

### eventType

A type all events holding this payload have.

``` swift
static var eventType: EventType 
```
