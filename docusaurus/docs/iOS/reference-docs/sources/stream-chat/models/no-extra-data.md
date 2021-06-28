---
title: NoExtraData
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

[`ChannelExtraData`](channel-extra-data.md), `Codable`, [`ExtraDataTypes`](../extra-data-types.md), `Hashable`, [`MessageExtraData`](message-extra-data.md), [`MessageReactionExtraData`](message-reaction-extra-data.md), [`UserExtraData`](user-extra-data.md)

## Properties

### `defaultValue`

Returns a concrete `NoExtraData` instance.

``` swift
public static var defaultValue: Self 
```
