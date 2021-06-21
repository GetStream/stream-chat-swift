---
id: attachmentaction 
title: AttachmentAction
--- 

An attachment action, e.g. send, shuffle.

``` swift
public struct AttachmentAction: Codable, Hashable 
```

## Inheritance

`Codable`, `Hashable`

## Initializers

### `init(name:value:style:type:text:)`

Init an attachment action.

``` swift
public init(
        name: String,
        value: String,
        style: ActionStyle,
        type: ActionType,
        text: String
    ) 
```

#### Parameters

  - name: a name.
  - value: a value.
  - style: a style.
  - type: a type.
  - text: a text.

## Properties

### `name`

A name.

``` swift
public let name: String
```

### `value`

A value of an action.

``` swift
public let value: String
```

### `style`

A style, e.g. primary button.

``` swift
public let style: ActionStyle
```

### `type`

A type, e.g. button.

``` swift
public let type: ActionType
```

### `text`

A text.

``` swift
public let text: String
```

### `isCancel`

Check if the action is cancel button.

``` swift
public var isCancel: Bool 
```
