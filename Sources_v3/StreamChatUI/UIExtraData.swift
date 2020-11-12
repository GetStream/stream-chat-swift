//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

public protocol ChannelUIExtraData: ChannelExtraData, NameAndImageProviding {}
public protocol UserUIExtraData: UserExtraData, NameAndImageProviding {}

extension NameAndImageExtraData: UserUIExtraData {}
extension NameAndImageExtraData: ChannelUIExtraData {}

public protocol UIExtraDataTypes: ExtraDataTypes {
    associatedtype User: UserUIExtraData = NameAndImageExtraData
    
    associatedtype Channel: ChannelUIExtraData = NameAndImageExtraData
}

public struct DefaultUIExtraData: UIExtraDataTypes {}

extension DefaultExtraData: UIExtraDataTypes {}
