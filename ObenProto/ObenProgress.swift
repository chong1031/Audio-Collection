//
//  ObenProgress.swift
//  ObenProto
//
//  Created by Will on 6/15/15.
//  Copyright (c) 2015 FFORM. All rights reserved.
//

import UIKit

class ObenProgress: UIView {

    //var HUD:M13ProgressHUD!
    private var lastProg:CGFloat = 0
    
    convenience init(view:UIView){
        
        self.init(frame:view.frame)
        
//        var prog = M13ProgressViewRing()
//        prog.primaryColor = ObenStyle.obenBlue
//        
//        HUD = M13ProgressHUD(progressView: prog)
//        HUD.progressViewSize = CGSizeMake(60, 60)
//        HUD.maskColor = UIColor(white: 1.0, alpha: 0.75)
//        HUD.maskType = M13ProgressHUDMaskTypeSolidColor
//        HUD.animationPoint =   CGPointMake( CGRectGetMidX(view.frame), CGRectGetMidY(view.frame))
//        view.addSubview(HUD)
    }
    
    func showProgress(visible:Bool){
        dispatch_async(dispatch_get_main_queue(), {
            if(visible){
                //HUD.show(true)
                JHProgressHUD.sharedHUD.showInWindow(self.window!)
            }else{
                //HUD.hide(true)
                JHProgressHUD.sharedHUD.hide()
            }
        })
    }
    
    func hideProgressWithDelay(delay:Bool){
        if(delay){
            Utilities.setTimeout(0.3){
                self.showProgress(false)
            }
        }else{
            self.showProgress(false)
        }
        
    }
    
    private func updateTitle(text:String){
        dispatch_async(dispatch_get_main_queue(), {
            JHProgressHUD.sharedHUD.updateTitle(text)
        })
    }
    
    func setProgress(progress:CGFloat, animated:Bool){
        //HUD.setProgress(progress, animated:animated)
        let perc = floor(progress * 100)
        self.updateTitle("\(perc)%")
        lastProg = progress
    }
    
    func setLabel(text:String){
        //HUD.status = text
        self.updateTitle(text)
    }
    
    func setProgAndLabel(progress:CGFloat, text:String){
        
        let perc = floor(progress * 100)
        self.setLabel(text)
        dispatch_async(dispatch_get_main_queue(), {
            JHProgressHUD.sharedHUD.showInWindow(UIApplication.sharedApplication().keyWindow!, withHeader: text, andFooter: "\(perc)%")    
        })
        
//        if(HUD.isVisible() == false){
//            self.setProgress(progress, animated: false)
//            self.showProgress(true)
//        }else{
//            self.setProgress(progress, animated: false)
//        }

        
    }
    
    func addProgress(increment:CGFloat){
        lastProg += increment
        self.setProgress( lastProg, animated: true)
    }
}
