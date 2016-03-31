import Cocoa

class SolidView: NSView {

    var backgroundColor: NSColor = NSColor.whiteColor() {
        didSet {
            drawRect(self.bounds)
        }
    }

    override func drawRect(dirtyRect: NSRect) {
        backgroundColor.setFill()
        NSRectFill(dirtyRect)
        super.drawRect(dirtyRect)
    }
}
