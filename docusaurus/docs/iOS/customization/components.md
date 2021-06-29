---
title: Components
---

## Customizing Components

`StreamChatUI` components are fully customizable and interchangeable. These are the steps that you need to follow to use a custom component:

1. Create a new component class by subclassing the component you want to change or its super class
1. Make changes to layout, styling, behavior as needed
1. Configure the SDK to use your custom component 

To make customizations as easy as possible all view components conform to the [Customizable](components#the-components-object) protocol and are subclasses of the `_View` base class. When building your own custom
component in most cases you only need to override or implement the methods from the `Customizable` protocol. 

:::note
Most UI components are stateless view classes. Components like `MessageList`, `ChannelList` and `MessageComposer` are stateful and are view controllers. Customization for these components is described in detail in their own doc pages.
:::


## The `Components` object

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

The full list of customizations exposed by `Components` is available [here](../common-content/reference-docs/stream-chat-ui/components.md#properties)

## Components Lifecycle Methods

To make subclassing and customization simple, `StreamChatUI` view components conform to the `Customizable` protocol. The protocol is very similar to UIKit's views lifecycle.

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
You can see this lifecycle method as a custom constructor of the view since it is only called once in the lifecycle of the component. Here it is a good place for setting delegates, adding gesture recognizers or adding any kind of target action. Usually you want to call `super.setUp()` when overriding this lifecycle method, but you can chose not to if you want to configure all the delegates and actions from scratch.

### `setUpAppearance()`
This lifecycle is where you can customize the appearance of the component, like changing colors, corner radius, everything that changes the style of the UI but not the layout. You should call `super.setUpAppearance()` if you only want to override some of the view's appearance and not everything.

### `setUpLayout()`
Here is where you should do customize the layout of the component, for example, changing the position of the views, padding, margins or even remove some child views. All the UI Components of the SDK use **AutoLayout** to layout the views, but our SDK provides a `ContainerStackView` component to make the customization easier. The `ContainerStackView` works very much like a `UIStackView`, in fact, it has almost the same API, but it is better suitable for our needs in terms of customizability. Just like the other lifecycle methods, you can call `super.setUpLayout()` depending on if you want to make the layout of the component from scratch or just want to change some parts of the component.

### `updateContent()`
Finally, this last lifecycle is called whenever the data of the component changes. Here is where you can change the logic of the component, change how the data is displayed or formatted. In the Stream SDK all of the components have a `content` propery that represents the data of the component. The rule of thumb to use this lifecycle is that if the change you want to do depends on the data of the component, then you should use this lifecycle method, even, for example, to do layout changes that are impacted by the content.

In addition to this, view components expose their content with the `content` property. For instance the `MessageContent` component `content`'s property holds the `ChatMessage` object.


## Example: custom avatar

Let's say, we want to change the appearance of avatars from the rounded ones to the rectangular ones. We can do this by subclassing the default component `ChatAvatarView` and by overriding the 

```swift
// Create custom subclass of `ChatAvatarView`
class RectAvatarView: ChatAvatarView {
    override func setUpAppearance() {
        super.setUpAppearance()
        
        imageView.layer.cornerRadius = 3
    }
}
```

And then set the custom component in `Components`:

```swift
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        /// ...
        Components.default.avatarView = RectAvatarView.self
        /// ...
    }
}
```
