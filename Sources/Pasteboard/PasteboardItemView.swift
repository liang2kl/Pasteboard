//
//  PasteboardItemView.swift
//  Pasteboard
//
//  Created by liang2kl on 2021/8/2.
//

import AppKit

class PasteboardItemViewWrapper: NSView {
    var pasteboardItemView: PasteboardItemView
    
    init(item: PasteboardItem, pinned: Bool) {
        pasteboardItemView = .init(item: item, pinned: pinned)
        
        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(pasteboardItemView)
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalTo: pasteboardItemView.widthAnchor, constant: 10),
            leadingAnchor.constraint(equalTo: pasteboardItemView.leadingAnchor, constant: -5),
            topAnchor.constraint(equalTo: pasteboardItemView.topAnchor),
            bottomAnchor.constraint(equalTo: pasteboardItemView.bottomAnchor)
        ])
        

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class PasteboardItemView: NSView {
    
    var pinIndicator: NSImageView!
    var contentView: NSView!
    var copyIndicator: NSTextField!
    
    var copyCount: Int = 0
    
    var item: PasteboardItem
    var pinned: Bool {
        didSet { updatePinImage() }
    }
    
    private var isDragging = false
    
    init(item: PasteboardItem, pinned: Bool) {
        self.item = item
        self.pinned = pinned
        super.init(frame: .zero)

        pinIndicator = CustomNSImageView(
            mouseUp: { _ in self.setPin() },
            mouseDown: { _ in }
        )
        
        updatePinImage()
        
        copyIndicator = NSTextField(labelWithString: NSLocalizedString("PASTEBOARD_ITEM_VIEW_COPIED_LABEL", comment: ""))

        copyIndicator.font = .monospacedSystemFont(ofSize: 13, weight: .medium)
        copyIndicator.textColor = .labelColor.withAlphaComponent(0.5)
        copyIndicator.isHidden = true
        
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

        addSubview(contentView)
        addSubview(copyIndicator)
        addSubview(pinIndicator)

        translatesAutoresizingMaskIntoConstraints = false
        pinIndicator.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        copyIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            pinIndicator.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            contentView.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 0.5),
            pinIndicator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
            contentView.trailingAnchor.constraint(equalToSystemSpacingAfter: trailingAnchor, multiplier: -0.5),
            widthAnchor.constraint(lessThanOrEqualToConstant: 300),
            widthAnchor.constraint(greaterThanOrEqualToConstant: 250),
            contentView.heightAnchor.constraint(lessThanOrEqualToConstant: 200),
            copyIndicator.trailingAnchor.constraint(equalTo: pinIndicator.leadingAnchor, constant: -10),
            copyIndicator.centerYAnchor.constraint(equalTo: pinIndicator.centerYAnchor)
        ])

        layer?.cornerRadius = 5
        layer?.cornerCurve = .continuous
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updatePinImage() {
        let name = pinned ? "pin.fill" : "pin"
        let image = NSImage(systemSymbolName: name, accessibilityDescription: "")!
        let color: NSColor = pinned ? .systemRed : .labelColor.withAlphaComponent(0.5)
        pinIndicator.contentTintColor = color
        pinIndicator.image = image
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
        pinIndicator.isHidden = false
    }
    
    override func mouseExited(with event: NSEvent) {
        layer?.backgroundColor = nil
        if !pinned {
            pinIndicator.isHidden = true
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        layer?.backgroundColor = NSColor.placeholderTextColor.cgColor
        isDragging = false
    }
    
    override func mouseUp(with event: NSEvent) {
        layer?.backgroundColor = NSColor.separatorColor.cgColor
        if !isDragging {
            copyItem()
        }
        isDragging = false
    }
    
    override func rightMouseUp(with event: NSEvent) {
        setPin()
    }
    
    override func mouseDragged(with event: NSEvent) {
        if !isDragging && pow(event.deltaX, 2) + pow(event.deltaY, 2) > 3 {
            isDragging = true
            let pasteboardItem = NSPasteboardItem()
            let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
            
            switch item {
            case .string:
                pasteboardItem.setDataProvider(self, forTypes: [.string])
                let image = NSImage(systemSymbolName: "text.badge.plus", accessibilityDescription: nil)!
                    .withSymbolConfiguration(.init(pointSize: 20, weight: .bold))!
                
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
        copyIndicator.isHidden = false
        copyCount &+= 1
        let currentCount = copyCount
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if currentCount == self.copyCount {
                self.copyIndicator.isHidden = true
            }
        }
        
    }

    @objc func setPin() {
        pinned.toggle()
        if pinned {
            PasteboardManager.shared.pinItem(item)
        } else {
            PasteboardManager.shared.unpinItem(item)
        }
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
