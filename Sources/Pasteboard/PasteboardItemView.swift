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
    
    private var isDragging = false
    
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
            contentView = textField
        case .image(let image, _, _):
            let imageView = CustomNSImageView(mouseUp: mouseUp, mouseDown: mouseDown)
            imageView.image = image
            imageView.imageScaling = .scaleProportionallyUpOrDown
            imageView.heightAnchor.constraint(lessThanOrEqualTo: imageView.widthAnchor, multiplier: image.size.height / image.size.width).isActive = true
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
            contentView.heightAnchor.constraint(lessThanOrEqualToConstant: 200)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createTrackingArea() {
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways]
        let trackingArea = NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
        
        guard var mouseLocation = self.window?.mouseLocationOutsideOfEventStream else { return }
        mouseLocation = self.convert(mouseLocation, to: nil)
        
        if self.bounds.contains(mouseLocation) {
            mouseEntered(with: .init())
        } else {
            mouseExited(with: .init())
        }
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        for trackingArea in self.trackingAreas {
            self.removeTrackingArea(trackingArea)
        }
        
        createTrackingArea()
        super.updateTrackingAreas()
    }

    override func mouseEntered(with event: NSEvent) {
        layer?.backgroundColor = NSColor.separatorColor.cgColor
    }
    
    override func mouseExited(with event: NSEvent) {
        layer?.backgroundColor = nil
    }
    
    override func mouseDown(with event: NSEvent) {
        layer?.backgroundColor = NSColor.placeholderTextColor.cgColor
        isDragging = false
    }
    
    override func mouseUp(with event: NSEvent) {
        layer?.backgroundColor = NSColor.separatorColor.cgColor
        isDragging = false
        copyItem()
    }
    
    override func mouseDragged(with event: NSEvent) {
        if !isDragging {
            isDragging = true
            let pasteboardItem = NSPasteboardItem()
            let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
            
            switch item {
            case .string:
                pasteboardItem.setDataProvider(self, forTypes: [.string])
                let image = NSImage(systemSymbolName: "text.badge.plus", accessibilityDescription: nil)!
                    .withSymbolConfiguration(.init(pointSize: 30, weight: .bold))!
                
                draggingItem.setDraggingFrame(.init(origin: .zero, size: image.size), contents: image)

            case .image(let image, _, _):
                pasteboardItem.setDataProvider(self, forTypes: [.png])
                draggingItem.setDraggingFrame(contentView.frame, contents: image)
            }
            beginDraggingSession(with: [draggingItem], event: event, source: self)
        }
    }
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
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
        mouseUp(with: .init())
    }
    
    func pasteboard(_ pasteboard: NSPasteboard?, item: NSPasteboardItem, provideDataForType type: NSPasteboard.PasteboardType) {
        guard let pasteboard = pasteboard else {
            return
        }

        self.item.copyToPasteboard(pasteboard)
    }
}

private class CustomNSImageView: NSImageView {
    var mouseUp: (NSEvent) -> Void
    var mouseDown: (NSEvent) -> Void
    
    init(mouseUp: @escaping (NSEvent) -> Void, mouseDown: @escaping (NSEvent) -> Void) {
        self.mouseUp = mouseUp
        self.mouseDown = mouseDown
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func mouseUp(with event: NSEvent) {
        mouseUp(event)
    }
    
    override func mouseDown(with event: NSEvent) {
        mouseDown(event)
    }
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}
