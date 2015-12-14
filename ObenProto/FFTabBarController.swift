//
//  TabBarControllerViewController.swift
//  ObenProto
//
//  Created by Will on 2/27/15.
//  Copyright (c) 2015 FFORM. All rights reserved.
//

import UIKit



class FFTabBarController: UITabBarController, UITabBarControllerDelegate,ModalViewControllerDelegate {

    private var loginIsOpen:Bool?
    
    override func viewDidLoad() {
       super.viewDidLoad()
       self.delegate = self
    
        self.loginIsOpen = false

        
        if(Preferences.shared.userPass.isEmpty || Preferences.shared.userEmail.isEmpty){
            // Need to show login sheet
            Utilities.setTimeout(0.1, completion: { () -> Void in
                self.openLogin()
            })
           
            
        }else{
            ObenAPI.shared.login({ (success:Bool) -> Void in
                print("Login return")
                if(!ObenAPI.shared.isLoggedIn()){
                    print("Not logged in, open modal")
                    dispatch_async(dispatch_get_main_queue(), {
                        //print("FORCE LOGIN SKIP FOR DOWN AWS SERVER")
                        //self.avatarOrMorph()
                        
                        self.openLogin()
                    })
                    
                }else{
                    dispatch_async(dispatch_get_main_queue(), {
                        self.avatarOrMorph()
                    })
                }
                
            })
        }
    }
    
    func openLogin(){
        if(loginIsOpen == true){
            print("Login already presented")
            return
        }
        print("open the login modal")
        dispatch_async(dispatch_get_main_queue(), {
            self.loginIsOpen = true
            self.performSegueWithIdentifier("needLogin", sender: self)
            if let lvc = self.presentedViewController as? LoginViewController{
                lvc.delegate = self
            }
        })
        
    }
    
    func logout(){
        ObenAPI.shared.logout()
        //if let morph = self.viewControllers?[1] as? AvatarViewController{
         //   morph.resetController()
        //}
        self.openLogin()
    }
    
    func modalDidFinished() {
        self.loginIsOpen = false
        self.avatarOrMorph()
    }
    
    func avatarOrMorph(){

        if(ObenAPI.shared.isLoggedIn()){
            print("Refresh Phrases")
            print("\(self.selectedViewController?.restorationIdentifier)")
            if (self.selectedViewController?.restorationIdentifier == "morph"){
                print("Is on the morph tab ")
                if let nvc = self.selectedViewController as? UINavigationController{
                    print(nvc.topViewController)
                    if let morph = nvc.topViewController as? SMAvatarList{
                        print("And morph is top")
                        morph.refreshAvatars()

                    }
                }
                
            }
        }
        
    }


    
    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        //print("Should select vc")
        /*
        if(viewController.restorationIdentifier == "morph"){

            var msg = ""
            if(!ObenAPI.shared.isLoggedIn()){
                msg = "You must be logged in to continue"
            }
            
            if(!msg.isEmpty){
                let alert = UIAlertController(title: "Error", message: msg, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                presentViewController(alert, animated: true, completion: nil)
                return false
            }
        }
        */
        return true
    }

    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//       print("prepare for seque \(segue.identifier)")
//    }
    

}
