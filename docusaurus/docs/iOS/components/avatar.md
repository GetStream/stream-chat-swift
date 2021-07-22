---
title: ChatAvatarView
---

import ComponentsNote from '../common-content/components-note.md'

This component renders the user avatar. By default, a circular image is used. 

### Customization

You can swap the built-in component with your own by setting `Components.default.avatarView` to your view type.

```swift
Components.default.avatarView = MyChatAvatarView.self
```

<ComponentsNote />

## Examples

### Square Avatar

First, create a subclass of `ChatAvatarView` and set it according to your needs. 

```swift
final class SquareAvatarView: ChatAvatarView {
    override func setUpAppearance() {
        super.setUpAppearance()
        imageView.layer.cornerRadius = 3
    }
}
``` 

Next, you need to set this custom view to `Components` in the context where your customization takes place. 

```swift
Components.default.avatarView = SquareAvatarView.self
```

| Default avatars | Square avatars |
| ------------- | ------------- |
| ![Chat with default message alignment](../assets/message-layout-default.png)  | ![Chat with square avatart](../assets/message-layout-squared-avatar.png)  |
