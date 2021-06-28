---
title: Custom Components
---

The Stream SDK has a `Components` configuration type that holds all the reusable views of the SDK. You can customize these views by subclassing them and replacing them in the configuration with your subclass. Just like the `Appearance` configuration type mentioned in the [Theming](../guides/ui-customization) page, you should modify the values of the `Components` configuration from `Components.default` as early as possible in your application life-cycle.

## The component lifecycle methods

To make subclassing and customization simple, all view components in the SDK have the following set of overridable lifecycle methods:

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

### setUp()
You can see this lifecycle method as a custom constructor of the view since it is only called once in the lifecycle of the component. Here it is a good place for setting delegates, adding gesture recognizers or adding any kind of target action. Usually you want to call `super.setUp()` when overriding this lifecycle method, but you can chose not to if you want to configure all the delegates and actions from scratch.

### setUpAppearance()
This lifecycle is where you can customize the appearance of the component, like changing colors, corner radius, everything that changes the style of the UI but not the layout. You should call `super.setUpAppearance()` if you only want to override some of the view's appearance and not everything.

### setUpLayout()
Here is where you should do customize the layout of the component, for example, changing the position of the views, padding, margins or even remove some child views. All the UI Components of the SDK use **AutoLayout** to layout the views, but our SDK provides a `ContainerStackView` component to make the customization easier. The `ContainerStackView` works very much like a `UIStackView`, in fact, it has almost the same API, but it is better suitable for our needs in terms of customizability. Just like the other lifecycle methods, you can call `super.setUpLayout()` depending on if you want to make the layout of the component from scratch or just want to change some parts of the component.

### updateContent()
Finally, this last lifecycle is called whenever the data of the component changes. Here is where you can change the logic of the component, change how the data is displayed or formatted. In the Stream SDK all of the components have a `content` propery that represents the data of the component. The rule of thumb to use this lifecycle is that if the change you want to do depends on the data of the component, then you should use this lifecycle method, even, for example, to do layout changes that are impacted by the content.

## Example: Custom Avatar View

Let's say, we want to change the appearance of avatars from the rounded ones to the rectangular ones. In this case, since it is a pretty simple example, we only need to change the appearance of the component:

```swift
class RectAvatarView: ChatAvatarView {
    override func setUpAppearance() {
        super.setUpAppearance()
        
        imageView.layer.cornerRadius = 3
    }
}
```

Then, we have to tell the SDK to use our custom subclass instead of the default type:
```swift
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        ...
        Components.default.avatarView = RectAvatarView.self
        ...
    }
}
```

| Before  | After |
| ------------- | ------------- |
| ![Default Avatars](https://github.com/GetStream/stream-chat-swift/wiki/default-avatars.png)  | ![Rect Avatars](https://github.com/GetStream/stream-chat-swift/wiki/rect-avatars.png)  |

And that's it 🎉 as you can see all avatars across the UI are now rectangular.

## Example: Custom Unread Count Indicator

Now, to show an example on how to use to other lifecycle methods, let's try to change the channel unread count indicator to look like the one in iMessage:

| Default style  | Custom "iMessage" Style |
| ------------- | ------------- |
| ![Default unread count](https://github.com/GetStream/stream-chat-swift/wiki/default-unread-count.png)  | ![iMessage unread count](https://github.com/GetStream/stream-chat-swift/wiki/custom-unread-count.png)  |

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
`
        customUnreadView.backgroundColor = tintColor
        customUnreadView.layer.masksToBounds = true
        customUnreadView.layer.cornerRadius = 5
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