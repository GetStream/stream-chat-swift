---
id: channeltype 
title: ChannelType
slug: referencedocs/sources/streamchat/models/channeltype
---

An enum describing possible types of a channel.

``` swift
public enum ChannelType: Codable, Hashable 
```

## Inheritance

`Codable`, `Hashable`

## Initializers

### `init(from:)`

``` swift
public init(from decoder: Decoder) throws 
```

## Enumeration Cases

### `livestream`

Sensible defaults in case you want to build livestream chat like Instagram Livestream or Periscope.

``` swift
case livestream
```

### `messaging`

Configured for apps such as WhatsApp or Facebook Messenger.

``` swift
case messaging
```

### `team`

If you want to build your own version of Slack or something similar, start here.

``` swift
case team
```

### `gaming`

Good defaults for building something like your own version of Twitch.

``` swift
case gaming
```

### `commerce`

Good defaults for building something like your own version of Intercom or Drift.

``` swift
case commerce
```

### `custom`

The type of the channel is custom.

``` swift
case custom(String)
```

Only small letters, underscore and numbers should be used

## Properties

### `title`

A channel type title.

``` swift
public var title: String 
```

### `rawValue`

A raw value of the channel type.

``` swift
public var rawValue: String 
```

## Methods

### `encode(to:)`

``` swift
public func encode(to encoder: Encoder) throws 
```
