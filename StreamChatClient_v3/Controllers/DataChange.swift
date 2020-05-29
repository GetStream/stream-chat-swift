//
// DataChange.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

// ULTRA WIP!
public enum Change<T> {
  case added(_ item: T)
  case updated(_ item: T)
  case moved(_ item: T)
  case removed(_ item: T)
}
