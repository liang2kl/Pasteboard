//
//  PasteboardObserver.swift
//  Pasteboard
//
//  Created by liang2kl on 2021/8/2.
//

import AppKit

class PasteboardObserver {
    @Published var pasteboardItems = [PasteboardItem]()
    @Published var latestItem: PasteboardItem?
    
    var timer: Timer?
    let pasteboard: NSPasteboard = .general
    var lastChangeCount: Int = 0
    
    func startObserving() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [unowned self] timer in
            if lastChangeCount != pasteboard.changeCount {
                lastChangeCount = pasteboard.changeCount
                NotificationCenter.default.post(name: .pasteboardDidChange, object: pasteboard)
                
                guard let item = pasteboard.pasteboardItems?.first else { return }
                
                if let string = item.string(forType: .string) {
                    setItem(.string(string: string, time: Date()))
                } else if let data = item.data(forType: .tiff),
                          let image = NSImage(data: data) {
                    setItem(.image(image: image, time: Date()))
                } else if let data = item.data(forType: .png),
                          let image = NSImage(data: data) {
                    setItem(.image(image: image, time: Date()))
                }
            }
        }
    }
    
    private func setItem(_ item: PasteboardItem) {
        latestItem = item
        pasteboardItems.append(item)
    }
    
    deinit {
        timer?.invalidate()
    }
}

enum PasteboardItem {
    case string(string: String, time: Date)
    case image(image: NSImage, time: Date)
    
    var time: Date {
        switch self {
        case .string(_, let time):
            return time
        case .image(_, let time):
            return time
        }
    }
    
    func copyToPasteboard() {
        switch self {
        case .string(let string, _):
            NSPasteboard.general.setString(string, forType: .string)
        case .image(let image, _):
            NSPasteboard.general.setData(image.pngData(), forType: .png)
        }
    }
}

extension NSNotification.Name {
    public static let pasteboardDidChange: NSNotification.Name = .init(rawValue: "pasteboardDidChangeNotification")
}
