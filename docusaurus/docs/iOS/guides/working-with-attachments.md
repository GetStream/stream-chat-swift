---
title: Working with Attachments/Files
---

Stream chat allows you to add attachments to a message. There is built-in support for files, images, videos, giphy and URL preview attachments.
It is also possible to have your own type of attachment and to customize how built-in attachments are rendered. Custom attachments are one of the most useful ways to add application specific content to messages. Examples of custom attachments are: location sharing, workouts and voice memos.

The type of attachment is defined by the value on the `Type` field. All SDKs support these built-in attachment types out-of-the-box:

- attachment type "image" for images
- attachment type "video" for videos
- attachment type "giphy" for interactive Giphy attachments (see Slack)
- attachment type "file" for files

URL previews can have type image, video or audio depending on the resource that the URL addresses. All attachments view classes are subclasses of the `AttachmentViewInjector` class.

All Chat SDKs allow you to customize how built-in types are handled as well as use your own custom attachment types.

## How to customize built-in attachments

Built-in attachments are mapped to specific `AttachmentViewInjector` classes, the mapping is defined on the `Components` class.

**Example:** change the view class used to render files attachments with a custom class.

```swift
Components.default.filesAttachmentInjector = MyCustomAttachmentViewInjector.self
```

This is the list of `Components`'s attributes used to map attachments to views

|  Attribute                | Description                                     | Default View Class                              |
|---------------------------|-------------------------------------------------|-------------------------------------------------|
| galleryAttachmentInjector | Single or multiple images and video attachments | `_GalleryAttachmentViewInjector<ExtraData>.self`|
| linkAttachmentInjector    | URL preview attachments                         | `_LinkAttachmentViewInjector<ExtraData> .self`  |
| giphyAttachmentInjector   | Giphy attachments                               | `_GiphyAttachmentViewInjector<ExtraData> .self` |
| filesAttachmentInjector   | File attachments                                | `_FilesAttachmentViewInjector<ExtraData> .self` |

You can implement `MyCustomAttachmentViewInjector` as a subclass of `FilesAttachmentViewInjector` or as a subclass of `AttachmentViewInjector`.

In both cases you will implement at least these two methods: `contentViewDidLayout(options: ChatMessageLayoutOptions)` and `contentViewDidUpdateContent`. 

To keep this easy to read we are going to create two classes: `MyCustomAttachmentViewInjector` and `MyCustomAttachmentView`. The latter can be a simple View class
or you can also use StreamChatUI's [_View](../ui-components/CommonViews/_View) class which is what we recommended.

```swift
import StreamChat
import StreamChatUI
import UIKit

class MyCustomAttachmentViewInjector: AttachmentViewInjector {
    let attachmentView = MyCustomAttachmentView()

    override func contentViewDidLayout(options: ChatMessageLayoutOptions) {
        contentView.bubbleContentContainer.insertArrangedSubview(attachmentView, at: 0, respectsLayoutMargins: true)
    }

    override func contentViewDidUpdateContent() {
        attachmentView.content = attachments(payloadType: FileAttachmentPayload.self).first
    }
}


class MyCustomAttachmentView: _View {
    var content: ChatMessageFileAttachment? {
        didSet { updateContentIfNeeded() }
    }

    override func setUpAppearance() {
        super.setUpAppearance()
    }

    override func setUpLayout() {
        super.setUpLayout()
    }

    override func updateContent() {
        super.updateContent()
    }
}

```

### Register the custom class to be used for file attachments

The last step is to inform the SDK to use `MyCustomAttachmentViewInjector` for file attachments instead of the default one. This is something that you want to do as early as possible in your application life-cycle.

```swift
Components.default.filesAttachmentInjector = MyCustomAttachmentViewInjector.self
```

## How to build a custom attachment

Stream chat allows you to create your own types of attachments as well. The steps to follow to add support for a custom attachment type are the following:

1. Extend `AttachmentType` to include the custom type
1. Create a new AttachmentPayload struct to handle your custom attachment data
1. Create a new AttachmentViewInjector 
1. Configure the SDK to use your view injector class to render custom attachments

Let's assume we want to attach a workout session to a message, the payload of the attachment will looks like this:


```json
{
  "type": "workout",
  "image_url": "https://path.to/some/great/picture.png",
  "workout-type": "walk",
  "workout-energy-cal": 75500,
  "workout-distance-meters": 1412,
  "workout-duration-seconds": 840
}
```

Here's how we get around the first two steps:

```swift
public extension AttachmentType {
    static let workout = Self(rawValue: "workout")
}

public struct WorkoutAttachmentPayload: AttachmentPayload {
    public var imageURL: URL

    public static var type: AttachmentType = .workout

    public var WorkoutDistanceMeters: Int?
    public var WorkoutType: String?
    public var WorkoutDurationSeconds: Int?
    public var WorkoutEnergyCal: Int?

    private enum CodingKeys: String, CodingKey {
        case WorkoutDistanceMeters = "workout-distance-meters"
        case WorkoutType = "workout-type"
        case WorkoutDurationSeconds = "workout-duration-seconds"
        case WorkoutEnergyCal = "workout-energy-cal"
        case imageURL = "image_url"
    }
}
```

Here we extended `AttachmentType` to include the `workout` type and afterwards we introduced a new struct to match the payload data that we expect. 

1. WorkoutAttachmentPayload.type is used to match message attachments to this struct
1. All attachment fields are optional, this is highly recommended for all custom data
1. We use CodingKeys to map JSON field names to struct fields

Let's now create a custom view injector to handle the workout attachment. 

```swift
import Nuke
import StreamChat
import StreamChatUI
import UIKit

class WorkoutAttachmentView: _View {
    var content: _ChatMessageAttachment<WorkoutAttachmentPayload>? {
        didSet { updateContentIfNeeded() }
    }

    let imageView = UIImageView()
    let distanceLabel = UILabel()
    let durationLabel = UILabel()
    let energyLabel = UILabel()

    override func setUpAppearance() {
        super.setUpAppearance()

        distanceLabel.backgroundColor = .yellow
        distanceLabel.numberOfLines = 0

        durationLabel.backgroundColor = .green
        durationLabel.numberOfLines = 0

        energyLabel.backgroundColor = .red
        energyLabel.numberOfLines = 0
    }

    override func setUpLayout() {
        super.setUpLayout()

        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)

        let container = ContainerStackView(arrangedSubviews: [distanceLabel, durationLabel, energyLabel])
        container.translatesAutoresizingMaskIntoConstraints = false
        container.distribution = .equal
        addSubview(container)

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: container.topAnchor),

            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    override func updateContent() {
        super.updateContent()

        if let attachment = content {
            Nuke.loadImage(with: attachment.imageURL, into: imageView)
            distanceLabel.text = "you walked \(attachment.WorkoutDistanceMeters ?? 0) meters!"
            durationLabel.text = "it took you \(attachment.WorkoutDurationSeconds ?? 0) seconds!"
            energyLabel.text = "you burned \(attachment.WorkoutEnergyCal ?? 0) calories!"
        } else {
            imageView.image = nil
            distanceLabel.text = nil
            durationLabel.text = nil
            energyLabel.text = nil
        }
    }
}

open class WorkoutAttachmentViewInjector: AttachmentViewInjector {
    let workoutView = WorkoutAttachmentView()

    override open func contentViewDidLayout(options: ChatMessageLayoutOptions) {
        contentView.bubbleContentContainer.insertArrangedSubview(workoutView, at: 0, respectsLayoutMargins: true)
    }

    override open func contentViewDidUpdateContent() {
        workoutView.content = attachments(payloadType: WorkoutAttachmentPayload.self).first
    }
}
```

The `WorkoutAttachmentView` class is where all layout and content logic happens, as you can see we are using [_View](../ui-components/CommonViews/_View) and [ContainerStackView](../ui-components/CommonViews/ContainerStackView)` from StreamChatUI instead of their UIKit counterpart. 
More information about this is available on their doc pages.

In `contentViewDidLayout` we add `WorkoutAttachmentView` as a subview of `bubbleContentContainer` using `insertArrangedSubview`, more information about layout customizations is available here. The last interesting bit happens in `contentViewDidUpdateContent`, there we use the `attachments` method to retrieve all attachments for this messages with type `WorkoutAttachmentPayload` and then pick the first one. This allows us to have the type we defined earlier as the content to render in our custom view.

Now that we have data and view ready we only need to configure the SDK to use `WorkoutAttachmentViewInjector` for workout attachments, this is done by changing the default `AttachmentViewCatalog` with our own.

```swift
class MyAttachmentViewCatalog: AttachmentViewCatalog {
    override class func attachmentViewInjectorClassFor(message: ChatMessage, components: Components) -> AttachmentViewInjector.Type? {
        guard message.attachmentCounts.keys.contains(.workout) else {
            return super.attachmentViewInjectorClassFor(message: message, components: components)
        }
        return WorkoutAttachmentViewInjector.self
    }
}

/// Config the SDK to use our attachment view catalog
Components.default.attachmentViewCatalog = MyAttachmentViewCatalog.self
```

The `AttachmentViewCatalog` class is used to pick the `AttachmentViewInjector` for a message, in our case we only need to check if the message contains a workout attachment.

If needed you can also send a message with a workout attachment directly from Swift just to test that everything works correctly:

```swift
let controller = client.channelController(for: ChannelId(type: .messaging, id: "my-test-channel"))
let attachment = WorkoutAttachmentPayload(WorkoutDistanceMeters: 150, WorkoutDurationSeconds: 42, WorkoutEnergyCal: 1000, imageURL: "https://path.to/some/great/picture.png")

controller.createNewMessage(text: "work-out-test", attachments: [.init(payload: attachment)]) { _ in
    print("test message was added")
}
```
