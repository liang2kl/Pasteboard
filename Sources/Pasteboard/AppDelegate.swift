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

    var manager = PasteboardManager.shared
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

    @IBAction func clearHistories(_ sender: NSMenuItem) {
        manager.pasteboardItems.removeAll()
    }
    @IBAction func showAboutView(_ sender: NSMenuItem) {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(nil)
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "p.circle.fill", accessibilityDescription: nil)
        statusItem.menu = menu
        menu.delegate = self
        
        manager.startObserving()
        
        if Defaults[.storingHistory] {
            manager.pasteboardItems = Defaults[.storedItems]
        }
        
        manager.$pasteboardItems
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
        while menu.items.count > 7 {
            menu.removeItem(at: 5)
        }
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        if manager.pasteboardItems.isEmpty {
            let item = NSMenuItem()
            item.title = "No Copied Content"
            menu.insertItem(item, at: 5)
            menu.insertItem(.separator(), at: 5)
        } else {
            for item in manager.pasteboardItems.reversed() {
                menu.insertItem(menuItem(for: item), at: 5)
                menu.insertItem(.separator(), at: 5)
            }
        }
    }
}
