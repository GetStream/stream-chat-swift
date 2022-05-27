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

## How to Customize Built-In Attachments

Built-in attachments are mapped to specific `AttachmentViewInjector` classes, the mapping is defined on the `Components` class.

**Example:** change the view class used to render files attachments with a custom class.

```swift
Components.default.filesAttachmentInjector = MyCustomAttachmentViewInjector.self
```

This is the list of `Components`'s attributes used to map attachments to views

|  Attribute                | Description                                     | Default View Class                              |
|---------------------------|-------------------------------------------------|-------------------------------------------------|
| galleryAttachmentInjector | Single or multiple images and video attachments | `GalleryAttachmentViewInjector.self`|
| linkAttachmentInjector    | URL preview attachments                         | `LinkAttachmentViewInjector.self`  |
| giphyAttachmentInjector   | Giphy attachments                               | `GiphyAttachmentViewInjector.self` |
| filesAttachmentInjector   | File attachments                                | `FilesAttachmentViewInjector.self` |

You can implement `MyCustomAttachmentViewInjector` as a subclass of `FilesAttachmentViewInjector` or as a subclass of `AttachmentViewInjector`.

In both cases you will implement at least these two methods: `contentViewDidLayout(options: ChatMessageLayoutOptions)` and `contentViewDidUpdateContent`. 

To keep this easy to read we are going to create two classes: `MyCustomAttachmentViewInjector` and `MyCustomAttachmentView`. The latter is your custom attachment view, you can implement it programmatically or with interface builder using xibs.

```swift
import StreamChat
import StreamChatUI
import UIKit

class MyCustomAttachmentViewInjector: AttachmentViewInjector {
    let attachmentView = MyCustomAttachmentView()

    override func contentViewDidLayout(options: ChatMessageLayoutOptions) {
        super.contentViewDidLayout(options: options)

        contentView.bubbleContentContainer.insertArrangedSubview(attachmentView, at: 0, respectsLayoutMargins: true)
    }

    override func contentViewDidUpdateContent() {
        super.contentViewDidUpdateContent()

        attachmentView.fileAttachment = attachments(payloadType: FileAttachmentPayload.self).first
    }
}


class MyCustomAttachmentView: UIView {
    ...
    var fileAttachment: ChatMessageFileAttachment? {
        didSet {
            update()
        }
    }

    func update() {
        // Update the UI here when the attachment changes
    }
}
```

The last step is to inform the SDK to use `MyCustomAttachmentViewInjector` for file attachments instead of the default one. This is something that you want to do as early as possible in your application life-cycle.

```swift
Components.default.filesAttachmentInjector = MyCustomAttachmentViewInjector.self
```

## How to Build a Custom Attachment

Stream chat allows you to create your own types of attachments as well. The steps to follow to add support for a custom attachment type are the following:

1. Extend `AttachmentType` to include the custom type
1. Create a new `AttachmentPayload` struct to handle your custom attachment data
1. Create a typealias for `ChatMessageAttachment<AttachmentPayload>` which will be used for the content of the view
1. Create a new `AttachmentViewInjector`
1. Configure the SDK to use your view injector class to render custom attachments

Let's assume we want to attach a workout session to a message, the payload of the attachment will look like this:


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

Here's how we get around the first three steps:

```swift
public extension AttachmentType {
    static let workout = Self(rawValue: "workout")
}

public typealias ChatMessageWorkoutAttachment = ChatMessageAttachment<WorkoutAttachmentPayload>

public struct WorkoutAttachmentPayload: AttachmentPayload {
    public static var type: AttachmentType = .workout

    var imageURL: URL
    var workoutDistanceMeters: Int?
    var workoutType: String?
    var workoutDurationSeconds: Int?
    var workoutEnergyCal: Int?

    private enum CodingKeys: String, CodingKey {
        case workoutDistanceMeters = "workout-distance-meters"
        case workoutType = "workout-type"
        case workoutDurationSeconds = "workout-duration-seconds"
        case workoutEnergyCal = "workout-energy-cal"
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

class WorkoutAttachmentView: UIView {
    var workoutAttachment: ChatMessageWorkoutAttachment? {
        didSet {
            update()
        }
    }

    let imageView = UIImageView()
    let distanceLabel = UILabel()
    let durationLabel = UILabel()
    let energyLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    func setupView() {
        distanceLabel.backgroundColor = .yellow
        distanceLabel.numberOfLines = 0

        durationLabel.backgroundColor = .green
        durationLabel.numberOfLines = 0

        energyLabel.backgroundColor = .red
        energyLabel.numberOfLines = 0

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

    func update() {
        if let attachment = workoutAttachment {
            Nuke.loadImage(with: attachment.imageURL, into: imageView)
            distanceLabel.text = "you walked \(attachment.workoutDistanceMeters ?? 0) meters!"
            durationLabel.text = "it took you \(attachment.workoutDurationSeconds ?? 0) seconds!"
            energyLabel.text = "you burned \(attachment.workoutEnergyCal ?? 0) calories!"
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
        super.contentViewDidLayout(options: options)

        contentView.bubbleContentContainer.insertArrangedSubview(workoutView, at: 0, respectsLayoutMargins: true)
    }

    override open func contentViewDidUpdateContent() {
        super.contentViewDidUpdateContent()

        workoutView.workoutAttachment = attachments(payloadType: WorkoutAttachmentPayload.self).first
    }
}
```

The `WorkoutAttachmentView` class is where all layout and content logic happens. In `contentViewDidLayout` we add `WorkoutAttachmentView` as a subview of `bubbleContentContainer` using `insertArrangedSubview`, more information about layout customizations is available [here](../uikit/custom-components.md). The last interesting bit happens in `contentViewDidUpdateContent`, there we use the `attachments` method to retrieve all attachments for this messages with type `WorkoutAttachmentPayload` and then pick the first one. This allows us to have the type we defined earlier as the content to render in our custom view.

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
let attachment = WorkoutAttachmentPayload(workoutDistanceMeters: 150, workoutDurationSeconds: 42, workoutEnergyCal: 1000, imageURL: "https://path.to/some/great/picture.png")

controller.createNewMessage(text: "work-out-test", attachments: [.init(payload: attachment)]) { _ in
    print("test message was added")
}
```

In case you need to interact with your custom attachment, there are a couple of steps required:
1. Create a delegate for your custom attachment view which extends from `ChatMessageContentViewDelegate`.
2. Create a custom `ChatMessageListVC` if you didn't already, and make it conform to the delegate created in step 1.
3. Change your custom injector and add a tap gesture recognizer to your custom view. The delegate can be called by accessing `contentView.delegate` and casting it to your custom delegate.

Below is the full example on how to add a interaction to the custom workout attachment:

```swift
// Step 1
protocol WorkoutAttachmentViewDelegate: ChatMessageContentViewDelegate {
    func didTapOnWorkoutAttachment(
        _ attachment: ChatMessageWorkoutAttachment
    )
}

// Step 2
class CustomChatMessageListVC: ChatMessageListVC, WorkoutAttachmentViewDelegate {
    func didTapOnWorkoutAttachment(_ attachment: ChatMessageWorkoutAttachment) {
        // For example, here you can present a view controller to display the workout
        let workoutViewController = WorkoutViewController(workout: attachment)
        navigationController?.pushViewController(workoutViewController, animated: true)
    }
}

// Step 3
class WorkoutAttachmentViewInjector: AttachmentViewInjector {
    let workoutView = WorkoutAttachmentView()

    override open func contentViewDidLayout(options: ChatMessageLayoutOptions) {
        super.contentViewDidLayout(options: options)

        contentView.bubbleContentContainer.insertArrangedSubview(workoutView, at: 0, respectsLayoutMargins: true)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapOnWorkoutAttachment))
        workoutView.addGestureRecognizer(tapGestureRecognizer)
    }

    override open func contentViewDidUpdateContent() {
        super.contentViewDidUpdateContent()
        
        workoutView.workoutAttachment = attachments(payloadType: WorkoutAttachmentPayload.self).first
    }

    @objc func handleTapOnWorkoutAttachment() {
        guard let workoutAttachmentDelegate = contentView.delegate as? WorkoutAttachmentViewDelegate {
            return
        }

        workoutAttachmentDelegate.didTapOnWorkoutAttachment(workoutView.content)
    }
}
```

Finally, don't forget to assign the custom message list if you didn't yet:
```swift
Components.default.messageListVC = CustomChatMessageListVC.self
```