//
//  Preferences.swift
//  ObenProto
//
//  Created by Will on 2/28/15.
//  Copyright (c) 2015 FFORM. All rights reserved.
//

import UIKit
import Security

class Preferences {
    
    private let manager = NSUserDefaults.standardUserDefaults()

    private let kIdentifier = "ObenProto"
    private let kEmail = "email"
    private let kPass = "pass"
    private let kDevelopment = "envIsDevelopment"
    private let kEnvironment = "env"
    private let kStreaming = "streaming"
    private let kMode = "recMode"
    private let kLanguage = "ttsLanguage"
    
    class var shared: Preferences {
        struct Static {
            static let instance: Preferences = Preferences()
        }
        return Static.instance
    }
    
    var userEmail: String{
        get{
            if let data = Keychain.load(kEmail){
                let val = NSString(data: data, encoding: NSUTF8StringEncoding)
                return String(val!)
            }
            return ""
        }
        set{
            Keychain.save(kEmail, data: newValue.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
        }
    }
    var userPass: String{
        get{
            if let data = Keychain.load(kPass){
                let val = NSString(data: data, encoding: NSUTF8StringEncoding)
                return String(val!)
            }
            return ""
        }
        set{
            Keychain.save(kPass, data: newValue.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
        }
    }
    var development: String{
        get{
            return self.manager.boolForKey(kDevelopment) ? "development":"production"
        }
        set{
            self.manager.setObject(newValue, forKey: kDevelopment)
        }
    }
    var environment: String{
        get{
            if let val = self.manager.stringForKey(kEnvironment){
                return val
            }
            return ""
        }
        set{
            self.manager.setObject(newValue, forKey: kEnvironment)
        }
    }
    
    var voiceStreaming: Bool{
        get{
            return self.manager.boolForKey(kStreaming)
        }
        set{
            self.manager.setBool(newValue, forKey: kStreaming)
        }
    }
    
    var streamingMethod: Int{
        get{
            return self.manager.integerForKey(kMode)
        }
        set{
            self.manager.setInteger(newValue, forKey: kMode)
        }
    }
    
    var ttsLanguage: String{
        get{
            if let val = self.manager.stringForKey(kLanguage){
                return val
            }
            return "EN"
        }
        set{
            self.manager.setObject(newValue, forKey: kLanguage)
        }
    }
}
