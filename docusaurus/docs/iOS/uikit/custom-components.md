---
title: Customizing Components
---

The Stream SDK UI components are fully customizable and interchangeable through the `Components` configuration type that holds all the reusable views of the SDK. You can customize these views by subclassing them and replacing them in the configuration with your subclass. Just like the `Appearance` configuration mentioned in the [Theming](theming.md) page, you should modify the values of the `Components` configuration from `Components.default` as early as possible in your application life-cycle.

## Customizing Components

These are the steps that you need to follow to use a custom component:

1. Create a new component class by subclassing the component you want to change.
1. Make changes to layout, styling, behavior as needed.
1. Configure the SDK to use your custom component.

To make customizations as easy as possible all view components share the same lifecycle and expose common properties such as `content`, `components` and `appearance`. When building your own custom
component in most cases you only need to override methods from the `Customizable` protocol such as `updateContent()`, `setUpAppearance()` or `setUpLayout()`.

:::note
Most UI components are stateless view classes. Components like `MessageList`, `ChannelList` and `MessageComposer` are stateful and are view controllers. Customizations for these components are described in detail in their own doc pages.
:::

## The `Components` object

You can provide your own component class via dependency injection. The SDK exposes this via the `Components` object and the `Components.default` singleton. You should provide all customizations as early as possible in your application.

Let's say that you have your own component to render messages called `MyCustomMessageView`. Here's an example how to register it in the SDK and replace the built-in one:

```swift
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        ...
        Components.default.messageContentView = MyCustomMessageView.self
        ...
    }
}
```

The full list of customizations exposed by `Components` is available [here](../common-content/reference-docs/stream-chat-ui/components.md#properties).

## Components Lifecycle Methods

To make subclassing and customization simple, `StreamChatUI` view components conform to the `Customizable` protocol.

```swift
/// Main point of customization for the view functionality.
func setUp()

/// Main point of customization for the view appearance.
func setUpAppearance()

/// Main point of customization for the view layout.
func setUpLayout()

/// Main point of customizing the way the view updates its content.
func updateContent()
```

### `setUp()`
You can see this lifecycle method as a custom constructor of the view since it is only called once in the lifecycle of the component. This is a good place for setting delegates, adding gesture recognizers or adding any kind of target action. Usually you want to call `super.setUp()` when overriding this lifecycle method, but you can choose not to if you want to configure all the delegates and actions from scratch.

### `setUpAppearance()`
This lifecycle method is where you can customize the appearance of the component, like changing colors, corner radius, everything that changes the style of the UI but not the layout. You should call `super.setUpAppearance()` if you only want to override part of the view's appearance and not everything.

### `setUpLayout()`
This method is where you should customize the layout of the component, for example, changing the position of the views, padding, margins or even remove some child views. All the UI Components of the SDK use **AutoLayout** to layout the views, but our SDK provides a `ContainerStackView` component to make the customization easier. The `ContainerStackView` works very much like a `UIStackView`, in fact, it has almost the same API, but it is better suitable for our needs in terms of customizability. Just like the other lifecycle methods, you can call `super.setUpLayout()` depending on if you want to make the layout of the component from scratch or just want to change some parts of the component.

### `updateContent()`
Finally, this method is called whenever the data of the component changes. Here you can change the logic of the component, change how the data is displayed or formatted. In the Stream SDK all of the components have a `content` property that represents the data of the component. This method should be used if the user interface depends on the data of the component.

In addition to this, view components expose their content with the `content` property. For instance the `MessageContent` component `content`'s property holds the `ChatMessage` object.

## Example: Custom Avatar

Let's say, we want to change the appearance of avatars by adding a border. In this case, since it is a pretty simple example, we only need to change the appearance of the component:

```swift
class BorderedAvatarView: ChatAvatarView {

    override func setUpAppearance() {
        super.setUpAppearance()

        imageView.layer.borderWidth = 1.0
        imageView.layer.borderColor = UIColor.green.cgColor
    }
}
```

Then, we have to tell the SDK to use our custom subclass instead of the default type:

```swift
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        ...
        Components.default.avatarView = BorderedAvatarView.self
        ...
    }
}
```

| Before  | After |
| ------------- | ------------- |
| ![Default Avatars](../assets/default-avatars.png)  | ![Bordered Avatars](../assets/bordered-avatars.png)  |

And that's it 🎉, as you can see all avatars across the UI are now with a border.

#### Change Avatar only in one view

In the previous example we saw that when we customized the avatar view, it changed every UI component that uses an avatar view. All the components in the `Components` configuration are shared components, but it is also possible to customize a shared component of a specific view only. Let's imagine that we want to apply the previous customization of a bordered avatar view, but only in the quoted reply view:

```swift
class CustomQuotedChatMessageView: QuotedChatMessageView {

    lazy var borderedAvatarView = BorderedAvatarView()

    override var authorAvatarView: ChatAvatarView {
        borderedAvatarView
    }
}
```

Then, set the custom component:

```swift
Components.default.quotedMessageView = CustomQuotedChatMessageView.self
```

As you can see, we override the `authorAvatarView` property of the `QuotedChatMessageView` component and provide our custom bordered avatar view. It is important that the overridden `authorAvatarView` is backed by a custom view which is created lazily, to avoid creating multiple instances of the same view when `authorAvatarView` is called.

| Before  | After |
| ------------- | ------------- |
| ![Default Avatars](../assets/default-avatars.png)  | ![Bordered Quote Avatar](../assets/bordered-quote-avatar.png)  |

## Example: Custom Unread Count Indicator

Now, to show an example on how to use the other lifecycle methods, let's try to change the channel unread count indicator to look like the one in iMessage:

| Default style  | Custom "iMessage" Style |
| ------------- | ------------- |
| ![Default unread count](../assets/default-unread-count.png)  | ![iMessage unread count](../assets/custom-unread-count.png)  |

First, we need to create a custom subclass of `ChatChannelListItemView`, which is the component responsible for showing the channel summary in the channel list. Because the iMessage-style unread indicator is just a blue dot, rather then trying to modify the existing unread indicator, it's easier to create a brand new view for it:

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

    override func setUpAppearance() {
        super.setUpAppearance()

        customUnreadView.backgroundColor = tintColor
        customUnreadView.layer.masksToBounds = true
        customUnreadView.clipsToBounds = true
    }

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

    override func updateContent() {
        super.updateContent()

        // We change the alpha value only because we want the view to still be part
        // of the layout system.
        customUnreadView.alpha = unreadCountView.content == .noUnread ? 0 : 1
    }
}
```

Finally, don't forget to change the `Components` configuration:

```swift
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        ...
        Components.default.channelContentView = iMessageChannelListItemView.self
        ...
    }
}
```
