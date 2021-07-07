---
title: Message Composer
---

import ComposerProperties from '../common-content/reference-docs/stream-chat-ui/composer/composer-vc-properties.md'
import ComposerViewProperties from '../common-content/reference-docs/stream-chat-ui/composer/composer-view-properties.md'
import ComposerContentProperties from '../common-content/reference-docs/stream-chat-ui/composer/composer-vc.content-properties.md'

The Message Composer component provides all the UI and necessary functionality for writing and sending messages. It supports sending text, handling chat commands, autocompletion, uploading attachments like images, files and video.

## Composer View Controller

The `ComposerVC` is the class responsible for the functionality of the composer, where the `ComposerView` is responsible for the UI layout. Both the `ComposerVC` and the `ComposerView` are totally customizable so that you can provide your own UI or extend the existing functionality.

### Basic Usage

#### TODO: how is the composer view used in your chat application, interaction with messagelist/channel screen

### Customization

The `ComposerVC` and `ComposerView` are completely customizable. You can not only change the UI layout and styling, but you can extend the composer functionality as well. In case you want to change the styling, adding new views and new functionality you can take a look at the [Customize Message Composer](../guides/customize-message-composer) guide. If you want to add a new custom attachment and make the composer to support it, you should read the [Message Composer Custom Attachments](../guides/working-with-custom-attachments) guide. 

### Properties

Complete list of all the components of `ComposerVC`.

<ComposerProperties/>

## Composer View
The `ComposerView` class which holds all the composer subviews and implements the composer layout. The composer layout is built with multiple `ContainerStackView`'s, which are very similar how  `UIStackView`'s work, you can read more about them [here](../customization/custom-components#setuplayout). This makes it very customizable since to change the layout you only need to move/remove/add views from different containers.

In the picture below you can see all the containers and main views of the composer:

<img src={require("../assets/ComposerVC_documentation.default-light.png").default} width="100%"/>

### Customization

#### TODO: you can use your own and configure the VC / SDK to use that one

### Properties 

Complete list of all the subviews that make the `ComposerView`.

<ComposerViewProperties/>

## Composer Content

The `ComposerVC.Content` is a struct that contains all the data that will be part of the composed message. It contains the current `text` of the message, the `attachments`, the `threadMessage` in case you are inside a Thread, the `command` if you are sending for example a Giphy, and the `state` of the composer to determine whether you are creating, editing or quoting a message. 

### Properties

Complete list of all the `ComposerVC.Content` data.

<ComposerContentProperties/>

## Composer State
The composer has three different states, `.new`, `.edit` and `.quote`. The `.new` state is when the composer is creating a new message, the `.edit` state is when we are editing an existing message and changing it's content, and finally, the `.quote` state is when we are replying a message inline (not in a thread). In the table below we can see the composer in all the three different states:

| `.new`  | `.edit` | `.quote` |
| ------------- | ------------- | ------------- |
| <img src={require("../assets/composer-ui-state-new.png").default} width="100%"/> | <img src={require("../assets/composer-ui-state-edit.png").default} width="100%"/> | <img src={require("../assets/composer-ui-state-quote.png").default} width="100%"/> |

#### TODO: how can you use composer state and customize states