//
// BundleExtensions.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

extension Bundle {
  /// A bundle id.
  var id: String? {
    infoDictionary?["CFBundleIdentifier"] as? String
  }

  /// A bundle name.
  var name: String? {
    object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String
  }
}
