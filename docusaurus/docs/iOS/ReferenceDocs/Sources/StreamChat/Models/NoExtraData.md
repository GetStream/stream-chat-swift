---
id: noextradata 
title: NoExtraData
slug: /ReferenceDocs/Sources/StreamChat/Models/noextradata
---

A type representing no extra data for the given model object.

``` swift
public struct NoExtraData: Codable,
    Hashable,
    UserExtraData,
    ChannelExtraData,
    MessageExtraData,
    MessageReactionExtraData,
    ExtraDataTypes 
```

## Inheritance

[`ExtraDataTypes`](../ExtraDataTypes), [`ChannelExtraData`](ChannelExtraData), `Codable`, `Hashable`, [`MessageExtraData`](MessageExtraData), [`MessageReactionExtraData`](MessageReactionExtraData), [`UserExtraData`](UserExtraData)

## Properties

### `defaultValue`

Returns a concrete `NoExtraData` instance.

``` swift
public static var defaultValue: Self 
```
