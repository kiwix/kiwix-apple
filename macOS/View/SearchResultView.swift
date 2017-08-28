//
//  SearchResultView.swift
//  macOS
//
//  Created by Chris Li on 8/23/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import Cocoa

class SearchResultTableCellView: NSTableCellView {
    @IBOutlet weak var titleField: NSTextField!
    @IBOutlet weak var snippetField: NSTextField!
    
    override var backgroundStyle: NSBackgroundStyle {
        didSet {
            titleField.textColor = backgroundStyle == .light ? NSColor.black : NSColor.selectedMenuItemTextColor
            let snippetColor = backgroundStyle == .light ? NSColor.labelColor : NSColor.textBackgroundColor
            let snippet = NSMutableAttributedString(attributedString: snippetField.attributedStringValue)
            let range = NSRange(location: 0, length: snippet.length)
            snippet.addAttribute(NSForegroundColorAttributeName, value: snippetColor, range: range)
            snippetField.attributedStringValue = snippet
        }
    }
}

class SearchResultTableRowView: NSTableRowView {
//    override func drawSeparator(in dirtyRect: NSRect) {
//        Swift.print(dirtyRect)
//        Swift.print(NSRect(x: 8, y: 0, width: dirtyRect.width - 8, height: dirtyRect.height))
//        super.drawBackground(in: dirtyRect.insetBy(dx: 8, dy: 8))
//    }
}

class SearchResultContainerController: NSWindowController {
    override func windowDidLoad() {
        let effect = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
        effect.blendingMode = .behindWindow
        effect.state = .active
        if #available(OSX 10.11, *) {
            effect.material = .menu
        } else {
            effect.material = .light
        }
        effect.wantsLayer = true
        effect.layer?.cornerRadius = 4.0
        window?.contentView = effect
        window?.titlebarAppearsTransparent = true
        window?.titleVisibility = .hidden
        window?.isOpaque = false
        window?.backgroundColor = .clear
        window?.standardWindowButton(NSWindowButton.closeButton)?.isHidden = true
        window?.standardWindowButton(NSWindowButton.miniaturizeButton)?.isHidden = true
        window?.standardWindowButton(NSWindowButton.fullScreenButton)?.isHidden = true
        window?.standardWindowButton(NSWindowButton.zoomButton)?.isHidden = true
    }
}

class SearchResultContainerView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.masksToBounds = true
        layer?.cornerRadius = 10.0
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        Swift.print(layer)
        layer?.masksToBounds = true
        layer?.cornerRadius = 10.0
    }
}
