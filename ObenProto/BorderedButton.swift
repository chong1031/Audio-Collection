
//  Created by Will on 1/20/15.
//  Copyright (c) 2015 FFORM. All rights reserved.
//

import UIKit

@IBDesignable class BorderedButton: UIButton {
    
    typealias buttonTouchInsideEvent = (sender: UIButton, num:Int) -> ()
    // MARK: Internals views
    var button : UIButton = UIButton(frame: CGRectZero)
    var isAnimated = true
    let animationDuration = 0.15
    // MARK: Callback
    var onButtonTouch: buttonTouchInsideEvent?
    var lastLabelColor:UIColor = UIColor.whiteColor()
    
    // MARK: IBSpec
    @IBInspectable var borderColor: UIColor = ObenStyle.obenBlue {
        didSet {
            self.layer.borderColor = borderColor.CGColor
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 0.5 {
        didSet {
            self.layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable var borderCornerRadius: CGFloat = 5.0 {
        didSet {
            self.layer.cornerRadius = borderCornerRadius
        }
    }
    
    @IBInspectable var labelColor: UIColor = ObenStyle.obenBlue {
        didSet {
            self.button.setTitleColor(labelColor, forState: .Normal)
        }
    }
    
    @IBInspectable var labelText: String = "Default" {
        didSet {
            self.button.setTitle(labelText, forState: .Normal)
        }
    }
    
    @IBInspectable var labelFontSize: CGFloat = 11.0 {
        didSet {
            self.button.titleLabel?.font = UIFont.systemFontOfSize(labelFontSize)
        }
    }
    
    required init(coder aDecoder: NSCoder)  {
        super.init(coder: aDecoder)!
        self.setup()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    func setup() {
        self.userInteractionEnabled = true
        
        self.button.addTarget(self, action: "onPress:", forControlEvents: .TouchDown)
        self.button.addTarget(self, action: "onRealPress:", forControlEvents: .TouchUpInside)
        self.button.addTarget(self, action: "onReset:", forControlEvents: .TouchUpInside)
        self.button.addTarget(self, action: "onReset:", forControlEvents: .TouchUpOutside)
        self.button.addTarget(self, action: "onReset:", forControlEvents: .TouchDragExit)
        self.button.addTarget(self, action: "onReset:", forControlEvents: .TouchCancel)
    }
    
    // MARK: views setup
    override func layoutSubviews() {
        super.layoutSubviews()
        
        //self.borderColor = ObenStyle.obenBlue
        //self.labelColor = ObenStyle.obenBlue
        //        self.borderWidth = 0.5
        //        self.borderCornerRadius = 5.0
        //        self.labelFontSize = 11.0
        
        self.button.frame = self.bounds
        self.button.titleLabel?.textAlignment = .Center
        self.button.backgroundColor = UIColor.clearColor()
        
        self.addSubview(self.button)
    }
    
    // MARK: Actions
    func onPress(sender: AnyObject) {
        UIView.animateWithDuration(self.isAnimated ? self.animationDuration : 0, animations: {
            self.lastLabelColor = self.labelColor
            self.labelColor = UIColor.whiteColor()
            self.backgroundColor = self.borderColor
        })
    }
    
    func onReset(sender: AnyObject) {
        UIView.animateWithDuration(self.isAnimated ? self.animationDuration : 0, animations: {
            self.labelColor = self.lastLabelColor
            self.backgroundColor = UIColor.clearColor()
        })
    }
    
    func onRealPress(sender: AnyObject) {
        if let btn = sender as? UIButton{
            self.onButtonTouch?(sender: btn, num:self.tag)
        }

    }
    
    func toggleEnabled(enValue:Bool?){
        if let v = enValue{
            self.enabled = v
        }else{
            self.enabled = !self.enabled
        }

        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.alpha = self.enabled ? 1.0 : 0.2
        })
    }
    
}

