//
//  ExtraDataHelper.swift
//  StreamChat
//
//  Created by Ajay Ghodadra on 04/02/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

public extension Dictionary where Key == String, Value == RawJSON {
    var minimumContribution: String? {
        if let minimumContribution = self["minimumContribution"] {
            return fetchRawData(raw: minimumContribution) as? String
        } else {
            return nil
        }
    }

    var charityThumb: String? {
        if let charityThumb = self["charityThumb"] {
            return fetchRawData(raw: charityThumb) as? String
        } else {
            return nil
        }
    }

    var safeAddress: String? {
        if let charityThumb = self["safeAddress"] {
            return fetchRawData(raw: charityThumb) as? String
        } else {
            return nil
        }
    }

    var daoName: String? {
        if let daoName = self["daoName"] {
            return fetchRawData(raw: daoName) as? String
        } else {
            return nil
        }
    }
}
