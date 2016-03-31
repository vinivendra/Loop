

import Cocoa


class CircleView: NSView {

    var backgroundColor: NSColor = NSColor.blueColor() {
        didSet {
            drawRect(self.bounds)
        }
    }

    override func drawRect(dirtyRect: NSRect) {
        backgroundColor.set()

        let cPath: NSBezierPath = NSBezierPath(ovalInRect: dirtyRect)
        cPath.fill()
    }
    
}
