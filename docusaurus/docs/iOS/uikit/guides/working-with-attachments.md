---
title: Working with Attachments/Files
---

Stream chat allows you to add attachments to a message. There is built-in support for files, images, videos, voice recordings, giphy and URL preview attachments.
It is also possible to have your own type of attachment and to customize how built-in attachments are rendered. Custom attachments are one of the most useful ways to add application specific content to messages. Examples of custom attachments are: location sharing and workouts.

The type of attachment is defined by the value on the `Type` field. All SDKs support these built-in attachment types out-of-the-box:

- attachment type `image` for images
- attachment type `video` for videos
- attachment type `voiceRecording` for voice recordings
- attachment type `giphy` for interactive Giphy attachments (see Slack)
- attachment type `file` for files

URL previews can have type image, video or audio depending on the resource that the URL addresses. All attachments view classes are subclasses of the `AttachmentViewInjector` class.

All Chat SDKs allow you to customize how built-in types are handled as well as use your own custom attachment types.

## How to Customize Built-In Attachments

Built-in attachments are mapped to specific `AttachmentViewInjector` classes, the mapping is defined on the `Components` class.

**Example:** change the view class used to render files attachments with a custom class.

```swift
Components.default.filesAttachmentInjector = MyCustomAttachmentViewInjector.self
```

This is the list of `Components`'s attributes used to map attachments to views

|  Attribute                        | Description                                     | Default View Class                          |
|-----------------------------------|-------------------------------------------------|---------------------------------------------|
| galleryAttachmentInjector         | Single or multiple images and video attachments | `GalleryAttachmentViewInjector.self`        |
| linkAttachmentInjector            | URL preview attachments                         | `LinkAttachmentViewInjector.self`           |
| giphyAttachmentInjector           | Giphy attachments                               | `GiphyAttachmentViewInjector.self`          |
| voiceRecordingAttachmentInjector  | Voice Recording attachments                     | `VoiceRecordingAttachmentViewInjector.self` |
| filesAttachmentInjector           | File attachments                                | `FilesAttachmentViewInjector.self`          |

You can implement `MyCustomAttachmentViewInjector` as a subclass of `FilesAttachmentViewInjector` or as a subclass of `AttachmentViewInjector`.

In both cases you will implement at least these two methods: `contentViewDidLayout(options: ChatMessageLayoutOptions)` and `contentViewDidUpdateContent`.

To keep this easy to read we are going to create two classes: `MyCustomAttachmentViewInjector` and `MyCustomAttachmentView`. The latter is your custom attachment view, you can implement it programmatically or with interface builder using XIBs.

```swift
import StreamChat
import StreamChatUI
import UIKit

class MyCustomAttachmentViewInjector: AttachmentViewInjector {
    let attachmentView = MyCustomAttachmentView()

    var message: ChatMessage? {
        contentView.content
    }

    override func contentViewDidLayout(options: ChatMessageLayoutOptions) {
        super.contentViewDidLayout(options: options)

        contentView.bubbleContentContainer.insertArrangedSubview(attachmentView, at: 0, respectsLayoutMargins: true)
    }

    override func contentViewDidUpdateContent() {
        super.contentViewDidUpdateContent()

        attachmentView.fileAttachment = message?.attachments(payloadType: FileAttachmentPayload.self).first
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
2. Create a new `AttachmentPayload` struct to handle your custom attachment data
3. Register the new attachment payload type in `ChatClient`
4. Create a `typealias` for `ChatMessageAttachment<AttachmentPayload>` which will be used for the content of the view
5. Create a new `AttachmentViewInjector`
6. Configure the SDK to use your view injector class to render custom attachments

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

In the code, the payload and attachment type should look something like this:

```swift
public extension AttachmentType {
    static let workout = Self(rawValue: "workout")
}

public typealias ChatMessageWorkoutAttachment = ChatMessageAttachment<WorkoutAttachmentPayload>

public struct WorkoutAttachmentPayload: AttachmentPayload {
    public static var type: AttachmentType = .workout

    var imageURL: URL?
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

1. `WorkoutAttachmentPayload.type` is used to match message attachments to this struct
2. All attachment fields are optional, this is highly recommended for all custom data
3. We use `CodingKeys` to map JSON field names to struct fields

Then, you should register your custom attachment type when creating the `ChatClient`, example:

```swift
let client = ChatClient(config: config)
client.registerAttachment(WorkoutAttachmentPayload.self)
```

:::note
The `ChatClient.registerAttachment()` is only available after the 4.42.0 release. This one was added to make sure that editing custom attachments is also supported.
:::

Let's now create a custom view injector to handle the workout attachment view.

```swift
import StreamChat
import StreamChatUI
import UIKit

class WorkoutAttachmentView: UIView, ComponentsProvider {
    var workoutAttachment: ChatMessageWorkoutAttachment? {
        didSet {
            update()
        }
    }

    lazy var imageView = UIImageView()
    lazy var distanceLabel = UILabel()
    lazy var durationLabel = UILabel()
    lazy var energyLabel = UILabel()

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
            components.imageLoader.loadImage(into: imageView, from: attachment.imageURL)
            distanceLabel.text = "you walked \(attachment.workoutDistanceMeters ?? 0) meters!"
            durationLabel.text = "it took you \(attachment.workoutDurationSeconds ?? 0) seconds!"
            energyLabel.text = "you burned \(attachment.workoutEnergyCal ?? 0) calories!"
        }
    }
}

open class WorkoutAttachmentViewInjector: AttachmentViewInjector {
    let workoutView = WorkoutAttachmentView()

    var message: ChatMessage? {
        contentView.content
    }

    override open func contentViewDidLayout(options: ChatMessageLayoutOptions) {
        super.contentViewDidLayout(options: options)

        contentView.bubbleContentContainer.insertArrangedSubview(workoutView, at: 0, respectsLayoutMargins: true)
    }

    override open func contentViewDidUpdateContent() {
        super.contentViewDidUpdateContent()

        workoutView.workoutAttachment = message?.attachments(payloadType: WorkoutAttachmentPayload.self).first
    }
}
```

The `WorkoutAttachmentView` class is where all layout and content logic happens. In `contentViewDidLayout` we add `WorkoutAttachmentView` as a subview of `bubbleContentContainer` using `insertArrangedSubview`. More information about layout customizations is available [here](../custom-components.md). The last interesting bit happens in `contentViewDidUpdateContent`, where we use the `attachments` method to retrieve all attachments for these messages with type `WorkoutAttachmentPayload` and then pick the first one. This allows us to have the type we defined earlier as the content to render in our custom view.

Now that we have data and view ready we only need to configure the SDK to use `WorkoutAttachmentViewInjector` for workout attachments. This is done by changing the default `AttachmentViewCatalog` with our own.

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

In case you want your attachments to be rendered along with other types of attachments, you need to register your custom injector to the `MixedAttachmentViewInjector` registry like so:

```swift
Components.default.mixedAttachmentInjector.register(.workout, with: WorkoutAttachmentViewInjector.self)
```

Then, you need to change your Catalog implementation to return the Mixed injector in case there are multiple types of attachments:

```swift
class MyAttachmentViewCatalog: AttachmentViewCatalog {
    override class func attachmentViewInjectorClassFor(message: ChatMessage, components: Components) -> AttachmentViewInjector.Type? {
        let hasMultipleTypesOfAttachments = message.attachmentCounts.keys.count > 1
        if message.attachmentCounts.keys.contains(.workout) {
            if hasMultipleTypesOfAttachments {
                return MixedAttachmentViewInjector.self
            }
            return WorkoutAttachmentViewInjector.self
        }
        return super.attachmentViewInjectorClassFor(message: message, components: components)
    }
}
```

If needed you can send a message with a workout attachment directly from Swift just to test that everything works correctly:

```swift
let controller = client.channelController(for: ChannelId(type: .messaging, id: "my-test-channel"))
let attachment = WorkoutAttachmentPayload(imageURL: URL(string: "https://path.to/some/great/picture.png"), workoutDistanceMeters: 150, workoutDurationSeconds: 42, workoutEnergyCal: 1000)

controller.createNewMessage(text: "work-out-test", attachments: [.init(payload: attachment)])
```

In case you need to interact with your custom attachment, there are a couple of steps required:
1. Create a delegate for your custom attachment view which extends from `ChatMessageContentViewDelegate`.
2. Create a custom `ChatMessageListVC` if you haven't already, and make it conform to the delegate created in step 1.
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
        guard let workoutAttachmentDelegate = contentView.delegate as? WorkoutAttachmentViewDelegate else {
            return
        }

        workoutAttachmentDelegate.didTapOnWorkoutAttachment(workoutView.content)
    }
}
```

Finally, don't forget to assign the custom message list if you haven't yet:
```swift
Components.default.messageListVC = CustomChatMessageListVC.self
```

### Quoted Message View Preview

A preview of the custom attachment view while a message containing such attachment is being quoted, needs to be provided as well.

In order to do this, you need to subclass the `QuotedChatMessageView` and provide your own implementation for the custom attachment type.

For example, let's create a `CustomQuotedMessageView` with the following implementation.

```swift
class CustomQuotedMessageView: QuotedChatMessageView {
    
    override func setAttachmentPreview(for message: ChatMessage) {
        if let customPayload = message.attachments(payloadType: WorkoutAttachmentPayload.self).first?.payload {
            attachmentPreviewView.contentMode = .scaleAspectFit
            attachmentPreviewView.image = appearance.images.fileFallback
            if textView.text.isEmpty {
                textView.text = customPayload.workoutType
            }
        }
        return super.setAttachmentPreview(for: message)
    }
}
```

In the subclass, we are overriding the implementation of the `setAttachmentPreview` method. We are checking if the message contains a custom attachment of type `WorkoutAttachmentPayload`. If it does, we are providing an image and a text available from the message payload.

Finally, you need to inject your custom implementation of the `CustomQuotedMessageView` in our `Components`'s property `quotedMessageView`.

```
Components.default.quotedMessageView = CustomQuotedMessageView.self
```

### Tracking custom attachment upload progress
In the previous examples, we assumed that you already have the custom attachment remote URL available. But, you can also upload the custom attachment through the Stream's SDK and observe the uploading progress.

The simplest approach is to upload the attachment through the `channelController.uploadAttachment()`. Using this function you can observe the progress, but the limitation is that at this time, the message is not yet sent, so this approach is good if you want to show the upload progress before creating the message. Here is an example:

```swift
let controller = client.channelController(for: ChannelId(type: .messaging, id: "my-test-channel"))
controller.uploadAttachment(
    localFileURL: localFileUrlFromUsersDevice,
    type: .workout,
    progress: { value in
        // Update here the upload progress
        someProgressView.update(with: value)
    },
    completion: { [weak self] result in
        // Don't forget to handle the error case
        guard let uploadedAttachment = try? result.get() else { return }
        let attachment = WorkoutAttachmentPayload(
            imageURL: uploadedAttachment.remoteURL, 
            workoutDistanceMeters: 150, 
            workoutDurationSeconds: 42, 
            workoutEnergyCal: 1000
        )
        self?.controller.createNewMessage(text: "work-out-test", attachments: [.init(payload: attachment)])
    }
)
```

In case you want to show the upload progress in the message cell, like it is shown in the Stream's native components, there are a couple of steps to go through:
1. Implement an `UploadedAttachmentPostProcessor` and inject it in `ChatClientConfig`. This is needed to update the remote URL once the attachment is successfully uploaded.
2. Create the custom attachment payload using `AnyAttachmentPayload(localFileURL:customPayload)` initializer and create the message instantly.
3. Observe the `AttachmentUploadingState` in your custom view. The message is updated whenever the attachment progress changes, and the progress can be read by the `attachment.uploadingState` property.

Below is a full example on how to show the uploading progress in the message cell:

```swift
// Step 1
public class CustomUploadedAttachmentPostProcessor: UploadedAttachmentPostProcessor {
    // This component is a helper class to update the payload of type-erased attachments.
    let attachmentUpdater = AnyAttachmentUpdater()

    public func process(uploadedAttachment: UploadedAttachment) -> UploadedAttachment {
        var attachment = uploadedAttachment.attachment

        attachmentUpdater.update(&attachment, forPayload: WorkoutAttachmentPayload.self) { payload in
            payload.imageURL = uploadedAttachment.remoteURL
        }

        return UploadedAttachment(attachment: attachment, remoteURL: uploadedAttachment.remoteURL)
    }
}

// Don't forget to inject it in the ChatClientConfig when creating your ChatClient
config.uploadedAttachmentPostProcessor = CustomUploadedAttachmentPostProcessor()

// Step 2
let controller = client.channelController(for: ChannelId(type: .messaging, id: "my-test-channel"))
let workoutPayload = WorkoutAttachmentPayload(
    imageURL: nil,
    workoutDistanceMeters: 150,
    workoutDurationSeconds: 42,
    workoutEnergyCal: 1000
)
let workoutAttachment = AnyAttachmentPayload(
    localFileURL: localFileUrlFromUsersDevice, 
    customPayload: workoutPayload
)
controller.createNewMessage(text: "work-out-test", attachments: [.init(payload: workoutAttachment)])

// Step 3
class WorkoutAttachmentView: UIView, ComponentsProvider {
    var workoutAttachment: ChatMessageWorkoutAttachment? {
        didSet {
            update()
        }
    }

    lazy var uploadingOverlayView = UploadingOverlayView()
    lazy var imageView = UIImageView()
    lazy var distanceLabel = UILabel()
    lazy var durationLabel = UILabel()
    lazy var energyLabel = UILabel()

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

        uploadingOverlayView.translatesAutoresizingMaskIntoConstraints = false

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
        addSubview(uploadingOverlayView)

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
            uploadingOverlayView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            uploadingOverlayView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            uploadingOverlayView.topAnchor.constraint(equalTo: imageView.topAnchor),
            uploadingOverlayView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),

            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func update() {
        if let attachment = workoutAttachment {
            // The uploadingOverlayView is used to show the uploading progress but you can use your own view.
            uploadingOverlayView.content = attachment.uploadingState
            components.imageLoader.loadImage(into: imageView, from: attachment.imageURL)
            distanceLabel.text = "you walked \(attachment.workoutDistanceMeters ?? 0) meters!"
            durationLabel.text = "it took you \(attachment.workoutDurationSeconds ?? 0) seconds!"
            energyLabel.text = "you burned \(attachment.workoutEnergyCal ?? 0) calories!"
        }
    }
}
```

For step 2, you can put this snippet in your custom composer when the user inserts a new attachment. You can read [here](../guides/message-composer-custom-attachments.md) on how to customize the message composer to support custom attachments.

As you can see, in the Step 3, the custom view is pretty much the same as the one from the previous examples, we only added an `UploadingOverlayView` to show the progress of the attachment. But, in order for this to work, it is required to do Step 1 and Step 2.
