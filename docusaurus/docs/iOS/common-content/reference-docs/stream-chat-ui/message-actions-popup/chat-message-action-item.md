---
title: ChatMessageActionItem
---

Protocol for action item.
Action items are then showed in `_ChatMessageActionsView`.
Setup individual item by creating new instance that conforms to this protocol.

``` swift
public protocol ChatMessageActionItem 
```

## Default Implementations

### `isPrimary`

``` swift
public var isPrimary: Bool 
```

### `isDestructive`

``` swift
public var isDestructive: Bool 
```

## Requirements

### title

Title of `ChatMessageActionItem`.

``` swift
var title: String 
```

### icon

Icon of `ChatMessageActionItem`.

``` swift
var icon: UIImage 
```

### isPrimary

Marks whether `ChatMessageActionItem` is primary.
Based on this property, some UI properties can be made.
Default value is `false`.

``` swift
var isPrimary: Bool 
```

### isDestructive

Marks whether `ChatMessageActionItem` is destructive.
Based on this property, some UI properties can be made.
Default value is `false`

``` swift
var isDestructive: Bool 
```

### action

Action that should be triggered when tapping on `ChatMessageActionItem`.

``` swift
var action: (ChatMessageActionItem) -> Void 
```
