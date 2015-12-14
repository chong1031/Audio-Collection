//
//  MorphSettingsViewController.swift
//  ObenProto
//
//  Created by Will on 7/27/15.
//  Copyright (c) 2015 FFORM. All rights reserved.
//

import UIKit

class MorphSettingsViewController: UIViewController {

    @IBOutlet weak var voidSpace: UIView!
    @IBOutlet weak var panel: UIView!
    @IBOutlet weak var panelHeight: NSLayoutConstraint!
    
    @IBOutlet weak var voiceMethod: UISegmentedControl!
    @IBOutlet weak var voiceMode: UISegmentedControl!
    @IBOutlet weak var ttsLanguage: UISegmentedControl!
    
    let languages = ["EN", "KO", "JA", "ZH"]
    var svc:SMViewController? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.clearColor()
        
        let blurEffect = UIBlurEffect(style: .Light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.view.bounds
        blurEffectView.opaque = false
        self.view.insertSubview(blurEffectView, atIndex: 0)
        
        self.view.alpha = 0
        
        let tapClose = UITapGestureRecognizer(target: self, action: "close:")
        let swipeClose = UISwipeGestureRecognizer(target: self, action: "close:")
        swipeClose.direction = UISwipeGestureRecognizerDirection.Down
        swipeClose.numberOfTouchesRequired = 1
        voidSpace.addGestureRecognizer(tapClose)
        voidSpace.addGestureRecognizer(swipeClose)
        panel.addGestureRecognizer(swipeClose)
        
        
    }
    
    override func viewWillAppear(animated: Bool) {
        self.panelHeight.constant = self.view.bounds.height
        self.panel.layoutIfNeeded()
        
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.view.alpha = 1.0
            self.panelHeight.constant = self.view.bounds.height / 2
            self.panel.layoutIfNeeded()
            self.voidSpace.layoutIfNeeded()
        })
        
        voiceMethod.selectedSegmentIndex = Preferences.shared.voiceStreaming ? 1 : 0
        voiceMode.selectedSegmentIndex = Preferences.shared.streamingMethod

        if let lang = languages.indexOf(Preferences.shared.ttsLanguage){
            ttsLanguage.selectedSegmentIndex = lang
        }
        
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    func close(sender:AnyObject){
        
        self.svc?.updateUI()
        
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.view.alpha = 0
            self.panelHeight.constant = self.view.bounds.height
            self.panel.layoutIfNeeded()
            self.voidSpace.layoutIfNeeded()
        }) { (success:Bool) -> Void in
            self.dismissViewControllerAnimated(false, completion: nil)
        }
    }

    
    @IBAction func segChange(sender: UISegmentedControl) {
        
        Preferences.shared.streamingMethod = voiceMode.selectedSegmentIndex
        Preferences.shared.voiceStreaming = voiceMethod.selectedSegmentIndex == 1
        Preferences.shared.ttsLanguage = languages[ttsLanguage.selectedSegmentIndex]
    }
}
