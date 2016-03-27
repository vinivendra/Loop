

import Cocoa


class SolidView: NSView {

    var backgroundColor: NSColor = NSColor.whiteColor()

    override func drawRect(dirtyRect: NSRect) {
        backgroundColor.setFill()
        NSRectFill(dirtyRect)
        super.drawRect(dirtyRect)
    }
}
