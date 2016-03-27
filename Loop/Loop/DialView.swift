

import Cocoa

class DialView: NSView {

    var borderColor = NSColor.blueColor() {
        didSet {
            outside.backgroundColor = borderColor
            inside.backgroundColor = borderColor
        }
    }
    var middleColor = NSColor.cyanColor() {
        didSet {
            middle.backgroundColor = middleColor
        }
    }

    override var frame: NSRect {
        didSet {
            resizeViews()
        }
    }

    var outside: CircleView!
    var middle: CircleView!
    var inside: CircleView!
    var center: CircleView!


    //
    required init?(coder: NSCoder) {
        super.init(coder: coder)

        self.commonInit()
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        self.commonInit()
    }

    func commonInit() {

        outside = CircleView()
        outside.backgroundColor = borderColor
        self.addSubview(outside)

        middle = CircleView()
        middle.backgroundColor = middleColor
        self.addSubview(middle)

        inside = CircleView()
        inside.backgroundColor = borderColor
        self.addSubview(inside)

        center = CircleView()
        center.backgroundColor = NSColor.whiteColor()
        self.addSubview(center)

        resizeViews()
    }

    func resizeViews() {
        let border: CGFloat = 3
        let thickness: CGFloat = width * 0.3

        outside.frame = NSRect(x: 0, y: 0, width: width, height: height)
        middle.frame = NSRect(x: border, y: border, width: width - 2 * border, height: height - 2 * border)
        inside.frame = NSRect(x: border + thickness, y: border + thickness, width: width - 2 * (border + thickness), height: height - 2 * (border + thickness))
        center.frame = NSRect(x: 2 * border + thickness, y: 2 * border + thickness, width: width - 2 * (2 * border + thickness), height: height - 2 * (2 * border + thickness))
    }
}



