//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat

var chatClient: ChatClient!
var channelController: ChatChannelController!

import UIKit

var window: UIWindow!

import Combine

@available(iOS 13.0, *)
var cancellables: Set<AnyCancellable> = []
