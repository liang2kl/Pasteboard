//
//  AppDelegate.swift
//  Pasteboard
//
//  Created by liang2kl on 2021/8/2.
//

import Cocoa
import Combine
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var observer = PasteboardObserver()
    var cancellables = Set<AnyCancellable>()
    
    var statusItem: NSStatusItem!

    @IBOutlet weak var menu: NSMenu!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "p.circle.fill", accessibilityDescription: nil)
        statusItem.menu = menu
        
        observer.startObserving()
        
        observer.$pasteboardItems
            .sink { items in print(items.count) }
            .store(in: &cancellables)
        
        observer.$latestItem
            .sink {
                guard let latestItem = $0 else { return }
                self.updateMenu(with: latestItem)
            }
            .store(in: &cancellables)
    }
    
    func updateMenu(with item: PasteboardItem) {
        menu.insertItem(menuItem(for: item), at: 3)
        menu.insertItem(.separator(), at: 3)
    }
    
    func menuItem(for item: PasteboardItem) -> NSMenuItem {
        let menu = NSMenuItem()
        menu.action = #selector(onStringMenuClick(_:))
        
        menu.view = PasteboardItemView(item: item)
//        menu.view!.frame.size = .init(width: 400, height: 200)
        return menu
    }
    
    @objc func onStringMenuClick(_ sender: NSMenuItem) {
        if let pasteboardItemView = sender.view as? PasteboardItemView {
            print(pasteboardItemView.item)
            pasteboardItemView.item.copyToPasteboard()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
}
