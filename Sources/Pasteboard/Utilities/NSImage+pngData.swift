//
//  NSImage+pngData.swift
//  Pasteboard
//
//  Created by liang2kl on 2021/8/2.
//

import AppKit

extension NSImage {
    func pngData() -> Data? {
        return tiffRepresentation?.bitmap?.png
    }
}

private extension NSBitmapImageRep {
    var png: Data? { representation(using: .png, properties: [:]) }
}

private extension Data {
    var bitmap: NSBitmapImageRep? { NSBitmapImageRep(data: self) }
}
