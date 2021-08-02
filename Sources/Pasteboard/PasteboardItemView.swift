//
//  PasteboardItemView.swift
//  Pasteboard
//
//  Created by liang2kl on 2021/8/2.
//

import AppKit

class PasteboardItemView: NSView {
    
    var timeLabel: NSTextField!
    var contentView: NSView!
    
    var item: PasteboardItem
    
    init(item: PasteboardItem) {
        self.item = item
        super.init(frame: .zero)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm"
        timeLabel = NSTextField(labelWithString: formatter.string(from: item.time))
        timeLabel.font = .monospacedSystemFont(ofSize: 12, weight: .medium)
        timeLabel.textColor = .placeholderTextColor
        
        switch item {
        case .string(let string, _):
            let textField = NSTextField(wrappingLabelWithString: string)
            textField.isEditable = false
            textField.isSelectable = false
            textField.maximumNumberOfLines = 10
            textField.font = .monospacedSystemFont(ofSize: 13, weight: .medium)
//            textField.lineBreakMode = .byCharWrapping
            contentView = textField
        case .image(let image, _):
            let imageView = NSImageView(image: image)
            contentView = imageView
        }
        
        wantsLayer = true

        addSubview(timeLabel)
        addSubview(contentView)
        translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            timeLabel.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            timeLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 1),
            contentView.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 4),
            contentView.leadingAnchor.constraint(equalTo: timeLabel.leadingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
            contentView.trailingAnchor.constraint(equalToSystemSpacingAfter: trailingAnchor, multiplier: -1),
            widthAnchor.constraint(lessThanOrEqualToConstant: 300),
            widthAnchor.constraint(greaterThanOrEqualToConstant: 250),
            heightAnchor.constraint(lessThanOrEqualToConstant: 300)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        for trackingArea in self.trackingAreas {
            self.removeTrackingArea(trackingArea)
        }
        
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways]
        let trackingArea = NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }

    override func mouseEntered(with event: NSEvent) {
        layer?.backgroundColor = NSColor.separatorColor.cgColor
    }
    
    override func mouseExited(with event: NSEvent) {
        layer?.backgroundColor = nil
    }
    
    override func mouseDown(with event: NSEvent) {
        layer?.backgroundColor = NSColor.placeholderTextColor.cgColor
        let pasteboardItem = NSPasteboardItem()
        let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
        
        switch item {
        case .string(let string, _):
            pasteboardItem.setDataProvider(self, forTypes: [.string])
            draggingItem.setDraggingFrame(self.bounds, contents: string)

        case .image:
            pasteboardItem.setDataProvider(self, forTypes: [.png])
            draggingItem.setDraggingFrame(self.bounds, contents: nil)
        }
        beginDraggingSession(with: [draggingItem], event: event, source: self)
    }
    
    @objc func copyItem() {
        PasteboardManager.shared.copyItem(item)
    }
}

extension PasteboardItemView: NSDraggingSource, NSPasteboardItemDataProvider {
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return .copy
    }
    
    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        layer?.backgroundColor = NSColor.separatorColor.cgColor
    }
    
    func pasteboard(_ pasteboard: NSPasteboard?, item: NSPasteboardItem, provideDataForType type: NSPasteboard.PasteboardType) {
        guard let pasteboard = pasteboard else {
            return
        }

        self.item.copyToPasteboard(pasteboard)
    }
}
