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
import Sparkle

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var manager = PasteboardManager.shared
    var cancellables = Set<AnyCancellable>()
    
    var currentItems = PasteboardManager.shared.pasteboardItems.map { $0.time }
    
    var statusItem: NSStatusItem!
    var noContentItem: NSMenuItem?
    
    var openKey: HotKey!
    
    let updater = SUUpdater()

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
            self.manager.pasteboardItems = Defaults[.storedItems]
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
        
        openKey = HotKey(key: .p, modifiers: [.option, .command])
        
        openKey.keyUpHandler = {
            self.statusItem.button?.performClick(nil)
        }
        
        updater.checkForUpdatesInBackground()
    }
    
    func menuItem(for item: PasteboardItem) -> NSMenuItem {
        let menu = NSMenuItem()
        menu.view = PasteboardItemView(item: item)
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
        openKey.isPaused = true
        if manager.pasteboardItems.isEmpty {
            while menu.items.count > 7 {
                menu.removeItem(at: 5)
            }
            
            let item = NSMenuItem()
            item.title = "No Copied Content"
            menu.insertItem(item, at: 5)
            menu.insertItem(.separator(), at: 5)
            noContentItem = item

        } else {
            if let item = noContentItem {
                let index = menu.index(of: item)
                menu.removeItem(at: index)
                menu.removeItem(at: index)
                noContentItem = nil
            }
            
            let times = manager.pasteboardItems.map { $0.time }
            let differences = times.difference(from: currentItems)
            
            for difference in differences {
                switch difference {
                case .insert: break
                case .remove(let offset, _, _):
                    menu.removeItem(at: menu.numberOfItems - 2 * offset - 4)
                    menu.removeItem(at: menu.numberOfItems - 2 * offset - 3)
                }
            }
            
            for difference in differences {
                switch difference {
                case .insert(let offset, _, _):
                    menu.insertItem(menuItem(for: manager.pasteboardItems[offset]), at: 5)
                    menu.insertItem(.separator(), at: 5)
                case .remove: break
                }
            }
        }
        
        currentItems = manager.pasteboardItems.map { $0.time }
    }
    
    func menuDidClose(_ menu: NSMenu) {
        openKey.isPaused = false
    }
}
