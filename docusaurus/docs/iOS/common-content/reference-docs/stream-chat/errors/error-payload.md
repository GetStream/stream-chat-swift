---
title: ErrorPayload
---

A parsed server response error.

``` swift
public struct ErrorPayload: LocalizedError, Codable, CustomDebugStringConvertible, Equatable 
```

## Inheritance

`Codable`, `CustomDebugStringConvertible`, `Equatable`, `LocalizedError`

## Properties

### `code`

An error code.

``` swift
public let code: Int
```

### `message`

A message.

``` swift
public let message: String
```

### `statusCode`

An HTTP status code.

``` swift
public let statusCode: Int
```

### `errorDescription`

``` swift
public var errorDescription: String? 
```

### `debugDescription`

``` swift
public var debugDescription: String 
```
