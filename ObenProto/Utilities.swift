//
//  Utilities.swift
//  ObenProto
//
//  Created by Will on 6/15/15.
//  Copyright (c) 2015 FFORM. All rights reserved.
//
import UIKit

func safeBool(value:AnyObject?) -> Bool{
    
    if let valBool = value as? Bool{
        return valBool
    }
    if let valStr = value as? String{
        return valStr == "false" ? false : true
    }
    
    return false
}
func safeInt(value:AnyObject?) -> Int{
    
    if let valInt = value as? Int{
        return valInt
    }
    if let valStr = value as? String{
        return Int(valStr)!
    }
    
    return 0
}
func safeStr(value:AnyObject?) -> String{
    
    if let valStr = value as? String{
        return valStr
    }
    if let valInt = value as? Int{
        return "\(valInt)"
    }
    
    return ""
}

class Utilities{
    
    class func setupDirectories(directories:Array<String>){
        print("Setup Directories")
        
        for path in directories{
            self.makeDirectory(path, clean:false)
        }
        
    }
    
    private static var lastEnv:Bool = false
    class func updateEnvironment(){
        if let window = UIApplication.sharedApplication().windows.first{
            
        print("Current environment \(Preferences.shared.environment)")
            
            if(Preferences.shared.environment != Preferences.shared.development){
                print("User changed environments")
                
                ObenAPI.shared.logout()
                Preferences.shared.environment = Preferences.shared.development
                
                
                if let tbc = window.rootViewController as? FFTabBarController{
                    dispatch_async(dispatch_get_main_queue(), {
                        tbc.openLogin()
                    })
                }
            }
        
            if( Preferences.shared.environment == "development" ){
                //window.tintColor = UIColor.redColor()
                UINavigationBar.appearance().barStyle = UIBarStyle.Default
                UINavigationBar.appearance().barTintColor = ObenStyle.obenBlue
                UINavigationBar.appearance().translucent = false
                UINavigationBar.appearance().tintColor = UIColor.whiteColor()
                UINavigationBar.appearance().titleTextAttributes = [
                    NSForegroundColorAttributeName: UIColor.whiteColor()
                ]
                UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: false)
            }else{
                UINavigationBar.appearance().barStyle = UIBarStyle.Default
                UINavigationBar.appearance().barTintColor = UIColor.whiteColor()
                UINavigationBar.appearance().translucent = false
                UINavigationBar.appearance().tintColor = ObenStyle.obenBlue
                UINavigationBar.appearance().titleTextAttributes = [
                    NSForegroundColorAttributeName: UIColor.blackColor()
                ]
                UINavigationBar.appearance().shadowImage = ObenStyle.imageOfMic

                UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: false)
            }
            
            window.setNeedsDisplay()
            window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
            window.rootViewController?.view.setNeedsDisplay()
            
        }
        
        
    }
    
    class func makeDirectory(path:String, clean:Bool){
        let fileManager = NSFileManager.defaultManager()
        if let newPath = self.urlForPath(path){
            var exists = fileManager.fileExistsAtPath(newPath.path!)

            if(clean && exists){
                try! fileManager.removeItemAtPath(newPath.path!)
                exists = false
            }
            
            if(!exists){
                try! fileManager.createDirectoryAtPath(newPath.path!, withIntermediateDirectories: true, attributes: nil)
            }
        }
        
    }
    
    class func urlForPath(path:String) -> NSURL? {
        if let docsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first {
            let path = "\(docsPath)/\(path)"
            return NSURL(fileURLWithPath: path)
        }
        return nil
    }
    
    class func setTimeout(delay:Double, completion:()->Void){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { () -> Void in
            completion()
        }
    }
    
    class func alertWithMessage(message:String, title:String, view:UIViewController){
        dispatch_async(dispatch_get_main_queue(), {
            let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            view.presentViewController(alert, animated: true, completion: nil)
        })
        
    }
    
    class func downloadFromRemoteURL(url:NSURL, toFileURL:NSURL) -> Bool{
        let manager = NSFileManager.defaultManager()
        
        
        print("checking")
        
        if(manager.fileExistsAtPath(toFileURL.path!)){
            //manager.removeItemAtPath(toFileURL.path!, error: nil)
            return true
        }
        
        
        let soundData = NSData(contentsOfURL: url)
        print("file doesn't exist, download it to \(toFileURL.path!)")
        if((soundData?.writeToFile(toFileURL.path!, atomically: true)) == true){
            return true
        }
        print("fallback")
        return false
    }
    
    
}