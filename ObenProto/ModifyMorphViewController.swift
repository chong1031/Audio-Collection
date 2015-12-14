//
//  ModifyMorphViewController.swift
//  ObenProto
//
//  Created by Will on 10/22/15.
//  Copyright © 2015 FFORM. All rights reserved.
//

import UIKit

struct MorphSettings{
    let pitch:Float
    let variability:Float
    let speed:Float
}

class ModifyMorphViewController: UIViewController {

    var morph:MorphResult!
    
    @IBOutlet weak var panelView: UIView!
    
    @IBOutlet weak var slidePitch: UISlider!
    @IBOutlet weak var slideVar: UISlider!
    @IBOutlet weak var slideSpeed: UISlider!
    
    @IBOutlet weak var btnPreview: UIButton!
    @IBOutlet weak var btnSave: UIButton!
    @IBOutlet weak var btnReset: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        panelView.layer.cornerRadius = 8.0
        let nilTap = UITapGestureRecognizer(target: self, action: nil)
        panelView.addGestureRecognizer(nilTap)
        
        let closeTap = UITapGestureRecognizer(target: self, action: "close")
        self.view.addGestureRecognizer(closeTap)
        view.opaque = false
        view.backgroundColor = UIColor(white: 0, alpha: 0.5)

        btnSave.enabled = false
    }
    
    override func viewWillAppear(animated: Bool) {
        self.view.alpha = 0
        
        panelView.transform = CGAffineTransformMakeScale(0.8, 0.8)
        UIView.animateWithDuration(0.6, delay: 0, usingSpringWithDamping: 80, initialSpringVelocity: 50, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.view.alpha = 1
            self.panelView.transform = CGAffineTransformMakeScale(1, 1)
            self.panelView.alpha = 1
        }, completion: nil)
        
    }

    func close(){
        self.panelView.transform = CGAffineTransformMakeScale(1, 1)
        self.panelView.alpha = 1
        self.view.alpha = 1

        UIView.animateWithDuration(0.3, delay:0, options: .CurveEaseOut, animations: { () -> Void in
            self.panelView.transform = CGAffineTransformMakeScale(0.8, 0.8)
            self.panelView.alpha = 0
        }, completion: nil)
        UIView.animateWithDuration(0.2, delay:0.1, options: .CurveEaseOut, animations: { () -> Void in
            self.view.alpha = 0
        }, completion: { (_:Bool) in
            self.dismissViewControllerAnimated(false, completion: nil)
        })
        
    }
    
    
    @IBAction func handleSliderChange(sender:UISlider){
        switch(sender){
        case slidePitch:
            print("Pitch change \(sender.value)")
        case slideVar:
            print("Var change \(sender.value)")
        case slideSpeed:
            print("Speed change \(sender.value)")
        default:
            print("Unknown slider")
        }
    }
    
    @IBAction func handlePreview(){
        ObenAPI.shared.modifyMorph(self.morph, settings: MorphSettings(pitch: slidePitch.value, variability: slideVar.value, speed: slideSpeed.value), mode: Preferences.shared.streamingMethod) { (result:String?) -> Void in
            
            if let str = result, url = NSURL(string: str){
                dispatch_async(dispatch_get_main_queue(), {
                        AudioControl.shared.playRemoteUrl(url)
                        self.btnSave.enabled = true
                })
                
            }
            
        }
    }
    
    @IBAction func handleSave(){
        ObenAPI.shared.modifyMorphSave(self.morph) { (success:Bool) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                if(success){
                    self.close();
                }else{
                    Utilities.alertWithMessage("Couldn't save your settings", title: "Error", view: self)
                }
            })
        }
    }
    
    @IBAction func handleReset(){
        close()
    }
}
