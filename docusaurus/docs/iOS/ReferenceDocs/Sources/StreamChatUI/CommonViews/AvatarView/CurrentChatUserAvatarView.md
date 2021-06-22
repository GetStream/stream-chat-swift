---
id: currentchatuseravatarview 
title: CurrentChatUserAvatarView
slug: /ReferenceDocs/Sources/StreamChatUI/CommonViews/AvatarView/currentchatuseravatarview
---

A UIControl subclass that is designed to show the avatar of the currently logged in user.

``` swift
open class _CurrentChatUserAvatarView<ExtraData: ExtraDataTypes>: _Control, ThemeProvider 
```

It uses `CurrentChatUserController` for its input data and is able to update the avatar automatically based
on the currently logged-in user.

## Inheritance

[`_Control`](../_Control), [`ThemeProvider`](../../Utils/ThemeProvider), `_CurrentChatUserControllerDelegate`

## Properties

### `controller`

`StreamChat`'s controller that observe the currently logged-in user.

``` swift
open var controller: _CurrentChatUserController<ExtraData>? 
```

### `avatarView`

The view that shows the current user's avatar.

``` swift
open private(set) lazy var avatarView: ChatAvatarView = components
        .avatarView.init()
        .withoutAutoresizingMaskConstraints
```

### `isEnabled`

``` swift
override open var isEnabled: Bool 
```

### `isHighlighted`

``` swift
override open var isHighlighted: Bool 
```

### `isSelected`

``` swift
override open var isSelected: Bool 
```

## Methods

### `setUpAppearance()`

``` swift
override open func setUpAppearance() 
```

### `setUp()`

``` swift
override open func setUp() 
```

### `setUpLayout()`

``` swift
override open func setUpLayout() 
```

### `updateContent()`

``` swift
@objc override open func updateContent() 
```

### `currentUserController(_:didChangeCurrentUser:)`

``` swift
public func currentUserController(
        _ controller: _CurrentChatUserController<ExtraData>,
        didChangeCurrentUser: EntityChange<_CurrentChatUser<ExtraData>>
    ) 
```
