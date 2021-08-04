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
import HotKey

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var manager = PasteboardManager.shared
    var cancellables = Set<AnyCancellable>()
    
    // Items that is currently (lastely) shown in the menu.
    var currentItems = [Date]()
    var currentPinnedItems = [Date]()
    
    var statusItem: NSStatusItem!
    var noContentItem: NSMenuItem?
    var pasteboardMenuItems = [(item: NSMenuItem, separator: NSMenuItem)]()
    var pinnedMenuItems = [(item: NSMenuItem, separator: NSMenuItem)]()
    
    var openKey: HotKey!
    var preferenceWindow: NSWindow?

    /// Connected to the status bar menu in the storyboard.
    @IBOutlet weak var menu: NSMenu!
    
    /// Connected to the `Preferences...` menu item in the storyboard.
    @IBAction func openPreferences(_ sender: NSMenuItem) {
        if preferenceWindow == nil {
            let vc = NSHostingController(rootView: SettingsView())
            preferenceWindow = NSWindow(contentViewController: vc)
            preferenceWindow?.title = "Preferences"
        }
        NSApp.activate(ignoringOtherApps: true)
        preferenceWindow?.makeKeyAndOrderFront(nil)
    }

    /// Connected to the `Clear` menu item in the storyboard.
    @IBAction func clearHistories(_ sender: NSMenuItem) {
        manager.pasteboardItems.removeAll()
    }
    
    /// Connected to the `About Pasteboard` menu item in the storyboard.
    @IBAction func showAboutView(_ sender: NSMenuItem) {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(nil)
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Setup status bar item and the menu.
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "p.circle.fill", accessibilityDescription: nil)
        // Connect the status bar menu to that of the item.
        statusItem.menu = menu
        menu.delegate = self
        
        // Start observing changes in the pasteboard.
        manager.startObserving()
        
        // Initialize pasteboard items storage from defaults.
        if Defaults[.storingHistory] {
            self.manager.pasteboardItems = Defaults[.storedItems]
        }
        self.manager.pinnedItems = Defaults[.pinnedItems]
        
        // Observe changes of the items and store them in defaults.
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
        
        manager.$pinnedItems
            .receive(on: DispatchQueue.global(qos: .background))
            .sink { items in
                Defaults[.pinnedItems] = items
            }
            .store(in: &cancellables)

        // Setup global hotkey to enable invoking the menu by `option` + `command` + `P`
        openKey = HotKey(key: .p, modifiers: [.option, .command])
        
        openKey.keyUpHandler = {
            self.statusItem.button?.performClick(nil)
        }
        
    }
    
    /// Returns a configured menu item for a pasteboard item.
    func menuItem(for item: PasteboardItem, pinned: Bool) -> NSMenuItem {
        let menu = NSMenuItem()
        menu.view = PasteboardItemView(item: item, pinned: pinned)
        return menu
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        FileManager.default.removeCache()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
}

extension AppDelegate: NSMenuDelegate {    
    func menuWillOpen(_ menu: NSMenu) {
        // Pause hotkey observation
        openKey.isPaused = true
        if manager.pasteboardItems.isEmpty && manager.pinnedItems.isEmpty {
            // Insert a label where there are no items
            while menu.items.count > 7 {
                menu.removeItem(at: 5)
            }
            
            let item = NSMenuItem()
            item.title = "No Copied Content"
            menu.insertItem(item, at: 5)
            menu.insertItem(.separator(), at: 5)
            noContentItem = item
            
        } else {
            // Remove the existing label, if there is one.
            if let item = noContentItem {
                let index = menu.index(of: item)
                menu.removeItem(at: index)
                menu.removeItem(at: index)
                noContentItem = nil
            }
            
            // Update items from the manager.
            updateItems()
            updatePinnedItems()
        }
        
        // Set current items as the items from the manager
        // have already displayed.
        currentItems = manager.pasteboardItems.map { $0.time }
        currentPinnedItems = manager.pinnedItems.map { $0.time }
    }
    
    func menuDidClose(_ menu: NSMenu) {
        openKey.isPaused = false
    }
    
    private func updateItems() {
        let times = manager.pasteboardItems.map { $0.time }
        let differences = times.difference(from: currentItems)
        
        let pinnedItemCount = currentPinnedItems.count * 2

        for difference in differences {
            switch difference {
            case .insert(let offset, _, _):
                let item = menuItem(for: manager.pasteboardItems[offset], pinned: false)
                let separator = NSMenuItem.separator()
                menu.insertItem(item, at: 5 + pinnedItemCount)
                menu.insertItem(separator, at: 5 + pinnedItemCount)
                // Store reference.
                pasteboardMenuItems.insert((item, separator), at: offset)
            case .remove(let offset, _, _):
                menu.removeItem(pasteboardMenuItems[offset].item)
                menu.removeItem(pasteboardMenuItems[offset].separator)
                pasteboardMenuItems.remove(at: offset)
            }
        }
    }
    
    private func updatePinnedItems() {
        let times = manager.pinnedItems.map { $0.time }
        let differences = times.difference(from: currentPinnedItems)
        
        for difference in differences {
            switch difference {
            case .insert(let offset, _, _):
                let item = menuItem(for: manager.pinnedItems[offset], pinned: true)
                let separator = NSMenuItem.separator()
                menu.insertItem(item, at: 5)
                menu.insertItem(separator, at: 5)
                // Store reference.
                pinnedMenuItems.insert((item, separator), at: offset)
            case .remove(let offset, _, _):
                menu.removeItem(pinnedMenuItems[offset].item)
                menu.removeItem(pinnedMenuItems[offset].separator)
                pinnedMenuItems.remove(at: offset)
            }
        }
    }
}
