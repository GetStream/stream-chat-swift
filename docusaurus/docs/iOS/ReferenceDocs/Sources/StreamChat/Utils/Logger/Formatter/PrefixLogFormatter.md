---
id: prefixlogformatter 
title: PrefixLogFormatter
slug: referencedocs/sources/streamchat/utils/logger/formatter/prefixlogformatter
---

Formats the given log message with the given prefixes by log level.
Useful for emphasizing different leveled messages on console, when used as:​
`prefixes:​ [.info:​ "ℹ️", .debug:​ "🛠", .error:​ "❌", .fault:​ "🚨"]`

``` swift
public class PrefixLogFormatter: LogFormatter 
```

## Inheritance

[`LogFormatter`](LogFormatter)

## Initializers

### `init(prefixes:)`

``` swift
public init(prefixes: [LogLevel: String]) 
```

## Methods

### `format(logDetails:message:)`

``` swift
public func format(logDetails: LogDetails, message: String) -> String 
```
