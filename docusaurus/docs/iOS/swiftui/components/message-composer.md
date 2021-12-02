---
title: Message composer
---

## Message Composer Overview

The message composer is the component that allows you to send messages consisting of text, images, video, files and links. The composer is customizable - you can provide your own views for several slots. The default component consists of several parts:

- Leading composer view - displayed in the left part of the component. The default implementation shows buttons for displaying media picker and giphy commands.
- Composer input view - the view that displays the input for the message. The default component allows adding text, as well as images, files and videos.
- Trailing composer view - displayed in the right part of the component. Usually used for sending the message.
- Attachment picker view - component that allows you to pick several different types of attachments. The default component has three types of attachments (images and videos from the photo library, files and camera input). When an attachment is selected, by default it is added to the composer's input view. You can inject custom views (alternative pickers) in the component itself as well. 

## Customizing the Leading Composer View

You can completely swap the leading composer view with your own implementation. This might be useful if you want to change the behaviour of the attachment picker (provide a different one), or even just hide the component. 

In order to do this, you need to implement the `makeLeadingComposerView`, which receives a binding of the `PickerTypeState`. Having the `PickerTypeState` as a parameter allows you to control the visibility of the attachment picker view. The `PickerTypeState` has two states - expanded and collapsed. If the state is collapsed, the composer is in the minimal mode (only the text input and leading and trailing areas are shown). If the enum state is expanded, it has associated value with it, which is of type `AttachmentPickerType`. This defines the type of picker which is currently displayed in the attachment picker view. The possible states are `none` (nothing is selected), `media` (media picker is selected), `giphy` (giphy commands picker is shown) and custom (for your own custom pickers).

Here's an example on how to provide a view for the leading composer view: 

```swift
public func makeLeadingComposerView(
        state: Binding<PickerTypeState>
) -> some View {
    AttachmentPickerTypeView(pickerTypeState: state)
}
```

## Customizing the AttachmentPickerTypeView

The `AttachmentPickerTypeView` comes with a lot of functionalities, in terms of image and video picker, file picker and selecting media from the camera. While you can just swap this component if it doesn't fit your needs (like shown above), it's also possible to extend it with additional message attachment types to fit your needs. 

For example, let's say we want to add additional contacts picker, which will allow us to send contacts via the chat. We also want to keep the existing functionalities, therefore we will explore ways to customize the existing component.

There are few things we need to do in order to accomplish this: 
- Introduce a new type of payload for contacts
- Create a new contact attachment type component
- Enable the new contact component to be selectable from the attachment types picker
- Implement the UI for previewing the selected item (contact) in the message composer
- Update the message resolving logic of the message list to include the contact payload
- Provide UI for the contacts attachment in the message list

Let's explore these steps in more details

### Contact Payload

First, we need to create a new `AttachmentType` for contacts, and define its payload.

```swift
extension AttachmentType {
    static let contact = Self(rawValue: "contact")
}

struct ContactAttachmentPayload: AttachmentPayload {
    static let type: AttachmentType = .contact

    let name: String
    let phoneNumber: String
}
```

Since we will go through the attachments in a scrollable list, we also need to conform the payload to the `Identifiable` protocol. For an id, it's enough to use a key that's a combination of the name and the phone number.

```swift
extension ContactAttachmentPayload: Identifiable {
    
    var id: String {
        "\(name)-\(phoneNumber)"
    }
    
}
```

### Create New Contact Attachment Type Component

Next, we need to create the component that will be displayed in the slot for custom attachment type pickers. In order to do inject our custom views, we need to create a new view factory, conforming to the `ViewFactory` protocol. The slot that's used for custom attachment type views can be filled via the `makeCustomAttachmentView` method from the `ViewFactory` protocol. This method has two parameters - one is for the list of already added custom attachments (maintained by the `MessageComposerViewModel`), and a callback that you should call when an attachment is tapped. In this method, we will return our newly created `CustomContactAttachmentView`, which will display a list of contacts. For simplicity, mock contacts are provided in the sample, but you can easily use the `Contacts` framework from Apple if you want to fetch the user's real contacts.

```swift
class CustomAttachmentsFactory: ViewFactory {

	@Injected(\.chatClient) var chatClient: ChatClient
    
    private let mockContacts = [
        CustomAttachment(
            id: "123",
            content: AnyAttachmentPayload(payload: ContactAttachmentPayload(name: "Test 1", phoneNumber: "071234234232"))
        ),
        CustomAttachment(
            id: "124",
            content: AnyAttachmentPayload(payload: ContactAttachmentPayload(name: "Test 2", phoneNumber: "4323243423432"))
        ),
        CustomAttachment(
            id: "125",
            content: AnyAttachmentPayload(payload: ContactAttachmentPayload(name: "Test 3", phoneNumber: "75756756756756"))
        )
    ]

    func makeCustomAttachmentView(
        addedCustomAttachments: [CustomAttachment],
        onCustomAttachmentTap: @escaping (CustomAttachment) -> Void
    ) -> some View {
        CustomContactAttachmentView(
            contacts: mockContacts,
            addedContacts: addedCustomAttachments,
            onCustomAttachmentTap: onCustomAttachmentTap
        )
    }

}
```

The `CustomContactAttachmentView` shows a list of the contacts, as well as an indicator about which contact is selected.

```swift
struct CustomContactAttachmentView: View {
    
    @Injected(\.fonts) var fonts
    @Injected(\.colors) var colors
    
    let contacts: [CustomAttachment]
    let addedContacts: [CustomAttachment]
    var onCustomAttachmentTap: (CustomAttachment) -> Void
        
    var body: some View {
        AttachmentTypeContainer {
            VStack(alignment: .leading) {
                Text("Contacts")
                    .font(fonts.headlineBold)
                    .standardPadding()
                
                ScrollView {
                    VStack {
                        ForEach(contacts) { contact in
                            if let payload = contact.content.payload as? ContactAttachmentPayload {
                                CustomContactAttachmentPreview(
                                    contact: contact,
                                    payload: payload,
                                    onCustomAttachmentTap: onCustomAttachmentTap,
                                    isAttachmentSelected: addedContacts.contains(contact)
                                )
                                .padding(.all, 4)
                                .padding(.horizontal, 8)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
        
}
```

In order to be consistent with the other attachment types, we're wrapping the view in the SDKs `AttachmentTypeContainer`, but that's optional if it doesn't fit your app's design. Next, we go through the contacts and display them in a `CustomContactAttachmentPreview` view, that we are going to be using in several other places. The view has a contact icon, the name of the person, and their phone number. If it's selected, it also displays a checkmark.

```swift
struct CustomContactAttachmentPreview: View {
    
    @Injected(\.fonts) var fonts
    @Injected(\.colors) var colors
    
    let contact: CustomAttachment
    let payload: ContactAttachmentPayload
    var onCustomAttachmentTap: (CustomAttachment) -> Void
    var isAttachmentSelected: Bool
    var hasSpacing = true
        
    var body: some View {
        Button {
            withAnimation {
                onCustomAttachmentTap(contact)
            }
        } label: {
            HStack {
                Image(systemName: "person.crop.circle")
                    .renderingMode(.template)
                    .foregroundColor(Color(colors.textLowEmphasis))
                
                VStack(alignment: .leading) {
                    Text(payload.name)
                        .font(fonts.bodyBold)
                        .foregroundColor(Color(colors.text))
                    Text(payload.phoneNumber)
                        .font(fonts.footnote)
                        .foregroundColor(Color(colors.textLowEmphasis))
                }
                
                if hasSpacing {
                    Spacer()
                }
                
                if isAttachmentSelected {
                    Image(systemName: "checkmark")
                        .renderingMode(.template)
                        .foregroundColor(Color(colors.textLowEmphasis))
                }
            }
            
        }
    }
    
}
```

### Make the Component Selectable in the Attachment Type Picker 

Next, we need to swap the current attachment picker, with a new one that will provide access to the custom component. To do this, we need to use the `makeAttachmentSourcePickerView` from the `ViewFactory` protocol. The method provides information about the selected `AttachmentPickerState`, as well as a callback that you should call when you want to switch the state. Here, we will return a new view, which will be of type `CustomAttachmentSourcePickerView`.

```swift
func makeAttachmentSourcePickerView(
        selected: AttachmentPickerState,
        onPickerStateChange: @escaping (AttachmentPickerState) -> Void
) -> some View {
    CustomAttachmentSourcePickerView(
        selected: selected,
        onTap: onPickerStateChange
    )
}
```

The `CustomAttachmentSourcePickerView` is an HStack of the default `AttachmentPickerButton`s for photos, files and camera. In addition to those, a new one is added for the contacts, which is of type custom. Note here that you don't have to use all attachment types. You can just remove any of those (for example files), if you don't want your composer to have such support. With this, our contacts view will be available as a selection in the attachment source picker view.

```swift
struct CustomAttachmentSourcePickerView: View {
    
    @Injected(\.colors) var colors
    
    var selected: AttachmentPickerState
    var onTap: (AttachmentPickerState) -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 24) {
            AttachmentPickerButton(
                iconName: "photo",
                pickerType: .photos,
                isSelected: selected == .photos,
                onTap: onTap
            )
            
            AttachmentPickerButton(
                iconName: "folder",
                pickerType: .files,
                isSelected: selected == .files,
                onTap: onTap
            )
            
            AttachmentPickerButton(
                iconName: "camera",
                pickerType: .camera,
                isSelected: selected == .camera,
                onTap: onTap
            )
            
            AttachmentPickerButton(
                iconName: "person.crop.circle",
                pickerType: .custom,
                isSelected: selected == .custom,
                onTap: onTap
            )
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(Color(colors.background1))
    }
    
}
```

### Previewing in the Message Composer's Input View

When any attachment is selected, it's displayed in the composer's input view. This notifies the user which attachments they are about to send in the chat. The composer's input view allows additional attachment previews to be injected in its own custom views slot. In our case, we want to display the selected contact.

In order to do this, we need the `makeCustomAttachmentPreviewView` method from the `ViewFactory`. This method is called with a list of the already added custom attachments, and a callback that needs to be called when the item is tapped. In our case, we will use this method to have a "remove attachment" button. We will return a new view called `CustomContactAttachmentComposerPreview`.

```swift
func makeCustomAttachmentPreviewView(
        addedCustomAttachments: [CustomAttachment],
        onCustomAttachmentTap: @escaping (CustomAttachment) -> Void
) -> some View {
    CustomContactAttachmentComposerPreview(
        addedCustomAttachments: addedCustomAttachments,
        onCustomAttachmentTap: onCustomAttachmentTap
    )    
}
```

In this view, we will just re-use the `CustomContactAttachmentPreview` we've created above (only without the checkmark functionality). In addition, we are adding the `DiscardAttachmentButton` from the SDK, to allow the possibility to remove the attachment from the composer's input view. You can provide your own version of this button, if needed. 

```swift
struct CustomContactAttachmentComposerPreview: View {
    
    var addedCustomAttachments: [CustomAttachment]
    var onCustomAttachmentTap: (CustomAttachment) -> Void
    
    var body: some View {
        VStack {
            ForEach(addedCustomAttachments) { contact in
                if let payload = contact.content.payload as? ContactAttachmentPayload {
                    HStack {
                        CustomContactAttachmentPreview(
                            contact: contact,
                            payload: payload,
                            onCustomAttachmentTap: onCustomAttachmentTap,
                            isAttachmentSelected: false
                        )
                        .padding(.leading, 8)
                        
                        Spacer()
                        
                        DiscardAttachmentButton(
                            attachmentIdentifier: payload.id,
                            onDiscard: { _ in
                                onCustomAttachmentTap(contact)
                            }
                        )
                    }
                    .padding(.all, 4)
                    .roundWithBorder()
                    .padding(.all, 2)
                }
            }
        }
    }
    
}
```

This is a good example on how to use composition to create new views while re-using the existing ones. With this, we are done with everything that needs to be done in order for you to send a custom attachment.

### Updating the Message Resolving Logic

Next, we need to go to the message list and update its rendering logic, in order for it to support displaying the newly created type of attachment. First, we need to update how messages are resolved based on their attachment types. The SDK supports displaying custom attachments via its `MessageTypeResolving` protocol. In our case, we need to create a new implementation of this protocol, specifically the `hasCustomAttachment` method. 

```swift
class CustomMessageTypeResolver: MessageTypeResolving {
    
    func hasCustomAttachment(message: ChatMessage) -> Bool {
        let contactAttachments = message.attachments(payloadType: ContactAttachmentPayload.self)
        return contactAttachments.count > 0
    }
    
}
```

In this method, we are saying the custom attachment views should be rendered if the message's attachments contain `ContactAttachmentPayload`. Next, we need to add the new resolver to the `StreamChat` client. In order to do this, please go back to the setup of the `StreamChat` instance in the `AppDelegate`, and provide the new implementation via the `Utils` class.

```swift
let messageTypeResolver = CustomMessageTypeResolver()
let utils = Utils(messageTypeResolver: messageTypeResolver)
         
streamChat = StreamChat(chatClient: chatClient, utils: utils)
```

### Providing New View in the Message List

The final step that we need to do is to provide a new view that the message list will render if the attachment type is of type `.contact`. To do this, we will go back to our custom view factory, and implement the `makeCustomAttachmentViewType` method. The method provides us the message that's going to be displayed, whether it's the first one (last sending date in a group) and the available width it has.

```swift
func makeCustomAttachmentViewType(
        for message: ChatMessage,
        isFirst: Bool,
        availableWidth: CGFloat
) -> some View {
    let contactAttachments = message.attachments(payloadType: ContactAttachmentPayload.self)
    return VStack {
        ForEach(0..<contactAttachments.count) { i in
            let contact = contactAttachments[i]
            CustomContactAttachmentPreview(
                contact: CustomAttachment(
                    id: "\(message.id)-\(i)",
                    content: AnyAttachmentPayload(payload: contact.payload)
                ),
                payload: contact.payload,
                onCustomAttachmentTap: { _ in },
                isAttachmentSelected: false,
                hasSpacing: false
            )
            .standardPadding()
        }
        .messageBubble(for: message, isFirst: true)
    }
}
```

In our implementation, we first extract the contact attachments. Then, we go through them and re-use the same `CustomContactAttachmentPreview` view we have created above. Additionally, we wrap it in a `.messageBubble` modifier, to fit with the rest of the messages.

## Summary

Those are the needed steps in order to have a custom attachment view. In a nutshell, we have first extended the attachment picker, to include the newly implemented contact picking view. Next, we told the composer about the new attachment type, and how to display it. After sending, we've customized our message list to know how to display the contacts attachment.

With this approach, you can provide any other custom attachments. For example, custom emojis, payments, maps, workout and anything else that your app needs to support.