import Cocoa

extension NSView {
    var width: CGFloat {
        get {
            return self.frame.size.width
        }
        set {
            self.frame = NSRect(x: self.frame.origin.x,
                y: self.frame.origin.y,
                width: newValue,
                height: self.frame.size.height)
        }
    }

    var height: CGFloat {
        get {
            return self.frame.height
        }
        set {
            self.frame = NSRect(x: self.frame.origin.x,
                y: self.frame.origin.y,
                width: self.frame.size.width,
                height: newValue)
        }
    }
}
