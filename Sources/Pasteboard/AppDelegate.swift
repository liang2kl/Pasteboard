//
//  AppDelegate.swift
//  Pasteboard
//
//  Created by liang2kl on 2021/8/2.
//

import Cocoa
import Combine
import SwiftUI
import Defaults

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var observer = PasteboardManager.shared
    var items = [PasteboardItem]()
    var cancellables = Set<AnyCancellable>()
    
    var statusItem: NSStatusItem!

    @IBOutlet weak var menu: NSMenu!
    @IBAction func openPreferences(_ sender: NSMenuItem) {
        let vc = NSHostingController(rootView: SettingsView())
        let window = NSWindow(contentViewController: vc)
        window.title = "Preferences"
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "p.circle.fill", accessibilityDescription: nil)
        statusItem.menu = menu
        menu.delegate = self
        
        observer.startObserving()
        
        if Defaults[.storingHistory] {
            observer.pasteboardItems = Defaults[.storedItems]
        }
        
        observer.$pasteboardItems
            .receive(on: DispatchQueue.global(qos: .background))
            .sink { items in
                guard Defaults[.storingHistory] else {
                    Defaults[.storedItems] = []
                    return
                }
                
                Defaults[.storedItems] = items
            }
            .store(in: &cancellables)
        
    }
    
    func menuItem(for item: PasteboardItem) -> NSMenuItem {
        let menu = NSMenuItem()
        menu.view = PasteboardItemView(item: item)
        return menu
    }
    
    @objc func onClick(_ sender: NSMenuItem) {
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
}

extension AppDelegate: NSMenuDelegate {
    func menuDidClose(_ menu: NSMenu) {
        while menu.items.count > 5 {
            menu.removeItem(at: 3)
        }
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        if observer.pasteboardItems.isEmpty {
            let item = NSMenuItem()
            item.title = "No Copied Content"
            menu.insertItem(item, at: 3)
            menu.insertItem(.separator(), at: 3)
        } else {
            for item in observer.pasteboardItems.reversed() {
                menu.insertItem(menuItem(for: item), at: 3)
                menu.insertItem(.separator(), at: 3)
            }
        }
    }
}
