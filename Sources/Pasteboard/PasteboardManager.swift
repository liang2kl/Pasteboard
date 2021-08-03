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
    private init() {
        Defaults.publisher(.maxStoreCount)
            .sink { _ in self.removeExceededItems() }
            .store(in: &cancellables)
    }
    
    @Published var pasteboardItems = [PasteboardItem]()
    @Published var latestItem: PasteboardItem?
    
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
            
            if let string = item.string(forType: .string) {
                setItem(.string(string: string, time: Date()))
            } else {
                setImagePasteboardItem(item)
            }
        }
    }
    
    private func setImagePasteboardItem(_ item: NSPasteboardItem) {
        guard let data = item.data(forType: .png) ?? item.data(forType: .tiff) else { return }
        guard let image = NSImage(data: data)?.downsampledImage() else { return }
        setItem(.image(image: image, data: data, time: Date()))
    }
    
    func copyItem(_ item: PasteboardItem) {
        DispatchQueue.global(qos: .background).async { [unowned self] in
            if let index = pasteboardItems.firstIndex(where: { $0.time == item.time }) {
                pasteboardItems.remove(at: index)
            }
            
            item.copyToPasteboard(self.pasteboard)
        }
    }
    
    private func setItem(_ item: PasteboardItem) {
        latestItem = item
        pasteboardItems.append(item)
        
        removeExceededItems()
    }
    
    private func removeExceededItems() {
        let maxRecords = Defaults[.maxStoreCount]
        // Maximum 20 records
        if pasteboardItems.count > maxRecords {
            (maxRecords..<pasteboardItems.count).forEach { pasteboardItems.remove(at: $0) }
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}
