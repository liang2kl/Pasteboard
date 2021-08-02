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
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd hh:mm:ss"
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
        case .image(let image, _):
            let imageView = NSImageView(image: image)
            contentView = imageView
        }
        
        super.init(frame: .zero)

        addSubview(timeLabel)
        addSubview(contentView)
        translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            timeLabel.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            timeLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 1),
            contentView.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 8),
            contentView.leadingAnchor.constraint(equalTo: timeLabel.leadingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
            timeLabel.trailingAnchor.constraint(equalToSystemSpacingAfter: trailingAnchor, multiplier: -1),
            contentView.trailingAnchor.constraint(equalToSystemSpacingAfter: trailingAnchor, multiplier: -1),
            contentView.heightAnchor.constraint(lessThanOrEqualToConstant: 300),
            contentView.widthAnchor.constraint(lessThanOrEqualToConstant: 400)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
