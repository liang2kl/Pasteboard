//
//  Defaults.swift
//  Pasteboard
//
//  Created by liang2kl on 2021/8/3.
//

import Foundation
import Defaults

extension Defaults.Keys {
    static let storedItems = Defaults.Key<[PasteboardItem]>("stored.pasteboard.items", default: [])
    static let pinnedItems = Defaults.Key<[PasteboardItem]>("pinned.pasteboard.items", default: [])
    static let maxStoreCount = Defaults.Key<Int>("max.count", default: 10)
    static let storingHistory = Defaults.Key<Bool>("storing.history", default: true)
}
