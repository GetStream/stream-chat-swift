---
id: clienterror 
title: ClientError
slug: referencedocs/sources/streamchat/errors/clienterror
---

A Client error.

``` swift
public class ClientError: Error, CustomStringConvertible 
```

## Inheritance

`CustomStringConvertible`, `Equatable`, `Error`

## Initializers

### `init(with:_:_:)`

A client error based on an external general error.

``` swift
public init(with error: Error? = nil, _ file: StaticString = #file, _ line: UInt = #line) 
```

#### Parameters

  - error: an external error.
  - file: a file name source of an error.
  - line: a line source of an error.

### `init(_:_:_:)`

An error based on a message.

``` swift
public init(_ message: String, _ file: StaticString = #file, _ line: UInt = #line) 
```

#### Parameters

  - message: an error message.
  - file: a file name source of an error.
  - line: a line source of an error.

## Properties

### `location`

The file and line number which emitted the error.

``` swift
public let location: Location?
```

### `underlyingError`

An underlying error.

``` swift
public let underlyingError: Error?
```

### `localizedDescription`

Retrieve the localized description for this error.

``` swift
public var localizedDescription: String 
```

### `description`

``` swift
public private(set) lazy var description = "Error \(type(of: self)) in \(location?.file ?? ""):\(location?.line ?? 0)"
        + (localizedDescription.isEmpty ? "" : " -> ")
        + localizedDescription
```

## Operators

### `==`

``` swift
public static func == (lhs: ClientError, rhs: ClientError) -> Bool 
```
