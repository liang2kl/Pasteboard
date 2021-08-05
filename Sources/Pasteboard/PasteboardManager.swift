//
//  PasteboardManager.swift
//  Pasteboard
//
//  Created by liang2kl on 2021/8/2.
//

import AppKit
import Defaults
import Combine

class PasteboardManager {
    static let shared = PasteboardManager()
    private init() {}
    
    @Published var pasteboardItems = [PasteboardItem]()
    @Published var pinnedItems = [PasteboardItem]()
    
    private var timer: Timer?
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    private var cancellables = Set<AnyCancellable>()
    
    func startObserving() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [unowned self] _ in
            DispatchQueue.global(qos: .background).async {
                detectChange()
            }
        }
    }
    
    private func detectChange() {
        if lastChangeCount != pasteboard.changeCount {
            lastChangeCount = pasteboard.changeCount
            
            guard let item = pasteboard.pasteboardItems?.first else { return }
            
            if let string = item.string(forType: .fileURL) {
                print(string)
            }
            
            if let string = item.string(forType: .string) {
                setStringPasteboardItem(with: string)
            } else {
                setImagePasteboardItem(item)
            }
        }
    }
    
    private func setStringPasteboardItem(with string: String) {
        if pinnedItems.contains(where: { $0.string == string }) { return }
        if let index = pasteboardItems.firstIndex(where: { $0.string == string }) {
            let item = pasteboardItems[index]
            pasteboardItems.remove(at: index)
            setItem(item)
            return
        }
        
        setItem(.string(string: string, time: Date()))
    }
    
    private func setImagePasteboardItem(_ item: NSPasteboardItem) {
        guard let data = item.data(forType: .png) ?? item.data(forType: .tiff) else { return }
        
        if pinnedItems.contains(where: { $0.imageData == data }) { return }
        if let index = pasteboardItems.firstIndex(where: { $0.imageData == data }) {
            let item = pasteboardItems[index]
            pasteboardItems.remove(at: index)
            setItem(item)
            return
        }
        
        guard let image = NSImage(data: data)?.downsampledImage() else { return }
        setItem(.image(image: image, data: data, time: Date()))
    }
    
    func copyItem(_ item: PasteboardItem) {
        DispatchQueue.global(qos: .background).async { [unowned self] in
            item.copyToPasteboard(self.pasteboard)
        }
    }
    
    func pinItem(_ item: PasteboardItem) {
        DispatchQueue.global(qos: .background).async { [unowned self] in
            if let index = pasteboardItems.firstIndex(where: { $0.time == item.time }) {
                pasteboardItems.remove(at: index)
            }
            
            pinnedItems.append(item)
        }
    }
    
    func unpinItem(_ item: PasteboardItem) {
        DispatchQueue.global(qos: .background).async { [unowned self] in
            if let index = pinnedItems.firstIndex(where: { $0.time == item.time }) {
                pinnedItems.remove(at: index)
            }
            
            pasteboardItems.append(item)
        }
    }
    
    private func setItem(_ item: PasteboardItem) {
        pasteboardItems.append(item)
        removeExceededItems()
    }
    
    private func removeExceededItems() {
        let maxRecords = Defaults[.maxStoreCount]

        if pasteboardItems.count > maxRecords {
            (0..<pasteboardItems.count - maxRecords).forEach {
                pasteboardItems.remove(at: $0)
            }
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}
