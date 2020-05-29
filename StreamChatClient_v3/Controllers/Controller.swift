//
// Controller.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// The base class for all controllers. Not meant to be used directly.
public class Controller: NSObject { // TODO: remove NSObject
  /// The queue which is used to perform callback calls. The default value is `.main`.
  public var callbackQueue: DispatchQueue = .main
}
