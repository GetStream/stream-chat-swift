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

`Codable`, [`ExtraDataTypes`](../../extra-data-types), [`ChannelExtraData`](../channel-extra-data), `Hashable`, [`MessageExtraData`](../message-extra-data), [`MessageReactionExtraData`](../message-reaction-extra-data), [`UserExtraData`](../user-extra-data)

## Properties

### `defaultValue`

Returns a concrete `NoExtraData` instance.

``` swift
public static var defaultValue: Self 
```
