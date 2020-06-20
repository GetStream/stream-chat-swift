//
// NoExtraData.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type representing no extra data for the given model object.
public struct NoExtraData: Codable, Hashable, UserExtraData, ChannelExtraData, MessageExtraData {}
