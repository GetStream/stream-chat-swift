---
title: Customizing UI Components
---

## Basic Customization

### Changing Brand Color

If suitable, UI elements respect `UIView.tintColor` as the main (brand) color. The current `tintColor` depends on the tint color of the view hierarchy the UI element is presented on.

For example, by changing the tint color of the `UIWindow` of the app, you can easily modify the brand color of the whole chat UI:

```swift
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = scene as? UIWindowScene else { return }
        scene.windows.forEach { $0.tintColor = .systemPink }
    }
}
```

| default `tintColor`  | `tintColor = .systemPink` |
| ------------- | ------------- |
| ![Chat UI with default tint color](https://github.com/GetStream/stream-chat-swift/wiki/blue-tint.png)  | ![Chat UI with pink tint color](https://github.com/GetStream/stream-chat-swift/wiki/pink-tint.png)  |


### Changing Colors and Fonts

`StreamChatUI` uses `Appearance` object to obtain the colors and fonts used by the components. This makes it easy to consistently change the look and feel of all elements the framework provides.

For example, this is what messages sent by the current user look like by default:

![Messages Default Appearance](https://github.com/GetStream/stream-chat-swift/wiki/default-appearance.png)

We can simply modify the colors and fonts used by modifying the `Appearance.default` value:
```swift
Appearance.default.fonts.body = .italicSystemFont(ofSize: 20)
Appearance.default.colorPalette.background6 = .yellow
```

![Messages Adjusted Appearance](https://github.com/GetStream/stream-chat-swift/wiki/adjusted-appearance.png)

You can see the font and the background color of the message has changed. Also note, that the font in the composer text view is also changed, since it uses the same semantic font as the body of the message.

### Changing Image Assets

`StreamChatUI` uses `Appearance` object to get the images assets used in the UI. For example, let's modify the icon used for the "Send" button:

![Custom Send Button](https://github.com/GetStream/stream-chat-swift/wiki/default-send-button.png)

```swift
Appearance.default.images.sendArrow = UIImage(systemName: "arrowshape.turn.up.right")!
```

![Default Send Button](https://github.com/GetStream/stream-chat-swift/wiki/custom-send-button.png)

If the same image is used in multiple places, changing the image in the `Appearance` object will update it in all places.

## Advanced Customization

`StreamChatUI` components are fully customizable. You can use as much of the built-in functionality as you need of every component to build the exact UI experience you want. The SDK uses `Components` object to obtain concrete types when instantiating the components. This mean, you can simply inject your custom subclass into tje `Components` object, and the SDK will use your custom subclass instead of the default one.

Let's say, we want to change the appearance of avatars from the rounded ones to the rectangular ones:

![Default Avatars](https://github.com/GetStream/stream-chat-swift/wiki/default-avatars.png)

```swift
// Create custom subclass of `ChatAvatarView`
class RectAvatarView: ChatAvatarView {
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.layer.cornerRadius = 3
    }
}

// Set the custom subclass in `Components`
Components.default.avatarView = RectAvatarView.self
```

And that's it 🎉 All avatars across the UI are now rectangular:

![Rect Avatars](https://github.com/GetStream/stream-chat-swift/wiki/rect-avatars.png)


### Component Lifecycle Methods

To make subclassing and customization simple, almost all view components in `StreamChatUI` has the following set of overridable lifecycle methods:

```swift
/// Main point of customization for the view functionality.
///
/// **It's called zero or one time(s) during the view's lifetime.** Calling super implementation is required.
func setUp()

/// Main point of customization for the view appearance.
///
/// **It's called multiple times during the view's lifetime.** The default implementation of this method is empty
/// so calling `super` is usually not needed.
func setUpAppearance()

/// Main point of customization for the view layout.
///
/// **It's called zero or one time(s) during the view's lifetime.** Calling super is recommended but not required
/// if you provide a complete layout for all subviews.
func setUpLayout()

/// Main point of customizing the way the view updates its content.
///
/// **It's called every time view's content changes.** Calling super is recommended but not required if you update
/// the content of all subviews of the view.
func updateContent()
```

### Example: Custom Unread Count Indicator

As an example of how to use these methods in practice, let's try to change the channel unread count indicator to look like the one in iMessage:

| Default style  | Custom "iMessage" Style |
| ------------- | ------------- |
| ![Default unread count](https://github.com/GetStream/stream-chat-swift/wiki/default-unread-count.png)  | ![iMessage unread count](https://github.com/GetStream/stream-chat-swift/wiki/custom-unread-count.png)  |


Firstly, we need to create a custom subclass of `ChatChannelListItemView`, which is the component responsible for showing the channel summary in the channel list. Because the iMessage-style unread indicator is just a blue dot, rather then trying to modify the existing unread indicator, it's easier to create a brand new view for it:

```swift
class iMessageChannelListItemView: ChatChannelListItemView {
    /// Blue "dot" indicator visible for channels with unread messages
    private lazy var customUnreadView = UIView()    
}
```

Then, we just follow the structure defined by the lifecycle methods and apply the proper customization for each step:
```swift
class iMessageChannelListItemView: ChatChannelListItemView {
    private lazy var customUnreadView = UIView()

    /// Main point of customization for the view appearance.
    ///
    /// **It's called multiple times during the view's lifetime.** The default implementation of this method is empty
    /// so calling `super` is usually not needed.
    override func setUpAppearance() {
        super.setUpAppearance()
`
        customUnreadView.backgroundColor = tintColor
        customUnreadView.layer.masksToBounds = true
        customUnreadView.layer.cornerRadius = 5
        customUnreadView.clipsToBounds = true
    }

    /// Main point of customization for the view layout.
    ///
    /// **It's called zero or one time(s) during the view's lifetime.** Calling super is recommended but not required
    /// if you provide a complete layout for all subviews.
    override func setUpLayout() {
        super.setUpLayout()

        // Set constraints for the new "dot" unread indicator
        NSLayoutConstraint.activate([
            customUnreadView.widthAnchor.constraint(equalTo: customUnreadView.heightAnchor),
            customUnreadView.widthAnchor.constraint(equalToConstant: 10),
        ])
        // Insert it as the left-most subview
        mainContainer.insertArrangedSubview(customUnreadView, at: 0)

        // Remove the original unread count indicator, since we don't need it anymore
        topContainer.removeArrangedSubview(unreadCountView)
    }

    /// Main point of customizing the way the view updates its content.
    ///
    /// **It's called every time view's content changes.** Calling super is recommended but not required if you update
    /// the content of all subviews of the view.
    override func updateContent() {
        super.updateContent()
        // We change the alpha value only because we want the view to still be part
        // of the layout system.
        customUnreadView.alpha = unreadCountView.content == .noUnread ? 0 : 1
    }
}
```

Finally, we have to tell the SDK to use our custom subclass instead of the default type:
```swift
Components.default.channelContentView = iMessageChannelListItemView.self
```
