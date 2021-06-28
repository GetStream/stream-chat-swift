---
title: Components
---

## Customizing Components

`StreamChatUI` components are fully customizable and interchangeable. These are the steps that you need to follow to use a custom component:

1. Create a new component class by subclassing the component you want to change or its super class
1. Make changes to layout, styling, behavior as needed
1. Configure the SDK to use your custom component 

To make customizations as easy as possible all view components conform to the [Customizable](components#customizable-protocol) protocol and are subclasses of the `_View` base class. When building your own custom
component in most cases you only need to override or implement the methods from the `Customizable` protocol. 

:::note
Most UI components are stateless view classes. Components like `MessageList`, `ChannelList` and `MessageComposer` are stateful and are view controllers. Customization for these components is described in detail in their own doc pages.
:::


### Components Customization

You can provide your own component class via dependency injection. The SDK exposes this via the `Components` object and the `Components.default` singleton. You should provide all customizations as early as possible in your application.

Let's say that you have your own component to render messages called `MyCustomMessageView`, this is how you register it to the SDK and replace the bulit-in one

```swift
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        /// ...

        Components.default.messageContentView = MyCustomMessageView.self       

        /// ...

        guard let _ = (scene as? UIWindowScene) else { return }

    }

    /// ...
}
```

The full list of customizations exposed by `Components` is available [here](../reference-docs/sources/stream-chat-ui/components.md#properties)

### Customizable Protocol

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

In addition to this, view components follow a clear naming convention and they all have the content being rendered stored as a property called `content`.

For instance the `MessageContent` component `content`'s property holds the `ChatMessage` object.


### Example: custom avatar

Let's say, we want to change the appearance of avatars from the rounded ones to the rectangular ones:

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
