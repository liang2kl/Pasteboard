//
//  PasteboardItem.swift
//  Pasteboard
//
//  Created by liang2kl on 2021/8/3.
//

import AppKit
import Defaults

enum PasteboardItem: Equatable {
    case string(string: String, time: Date)
    case image(image: NSImage, data: Data, time: Date)
    
    var time: Date {
        switch self {
        case .string(_, let time):
            return time
        case .image(_, _, let time):
            return time
        }
    }
    
    func copyToPasteboard(_ pasteboard: NSPasteboard) {
        switch self {
        case .string(let string, _):
            pasteboard.declareTypes([.string], owner: nil)
            pasteboard.setString(string, forType: .string)
        case .image(_, let data, _):
            pasteboard.declareTypes([.png], owner: nil)
            pasteboard.setData(data, forType: .png)
        }
    }
    
    static func == (lhs: PasteboardItem, rhs: PasteboardItem) -> Bool {
        return lhs.time == rhs.time
    }
}

extension PasteboardItem: Codable, DefaultsSerializable {
    
    var imageData: Data? {
        if case .image(_, let data, _) = self {
            return data
        }
        return nil
    }
    
    var string: String? {
        if case .string(let string, _) = self {
            return string
        }
        return nil
    }
    
    enum CodingKeys: CodingKey {
        case string, time, image
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let data = imageData {
            try container.encode(data, forKey: .image)
        }
        
        if let string = string {
            try container.encode(string, forKey: .string)
        }
        
        try container.encode(time, forKey: .time)
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let time = try values.decode(Date.self, forKey: .time)
        if let data = try? values.decode(Data.self, forKey: .image),
           let image = NSImage(data: data) {
            let compressedImage = image.downsampledImage()!
            self = .image(image: compressedImage, data: data, time: time)
        } else {
            let string = try! values.decode(String.self, forKey: .string)
            self = .string(string: string, time: time)
        }
    }
}
