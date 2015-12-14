//
//  LoginViewController.swift
//  ObenProto
//
//  Created by Will on 2/28/15.
//  Copyright (c) 2015 FFORM. All rights reserved.
//

import UIKit

protocol ModalViewControllerDelegate{
    func modalDidFinished()
}

class LoginViewController: UIViewController, UITextFieldDelegate {

    var delegate: ModalViewControllerDelegate! = nil
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    override func viewDidLoad() {
        print("login view loaded")
        super.viewDidLoad()
        emailField.becomeFirstResponder()
        emailField.delegate = self
        passwordField.delegate = self
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {

        let nextTag = textField.tag + 1
        if let next:UIResponder = textField.superview?.viewWithTag(nextTag){
            next.becomeFirstResponder()
        }else{
            textField.resignFirstResponder()
            processLogin()
        }

        return true
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func login(sender: AnyObject) {
        processLogin()
    }
    
    func processLogin(){
        print("Try to login")
        let email = emailField.text!
        let pass =  passwordField.text!

        if(email.isEmpty || pass.isEmpty){
            let alert = UIAlertController(title: "Error", message: "Need an email and password", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            presentViewController(alert, animated: true, completion: nil)
        }else{
            Preferences.shared.userEmail = email
            Preferences.shared.userPass  = pass
            loginButton.enabled = false
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            ObenAPI.shared.login({ (success:Bool) -> Void in
                self.loginButton.enabled = true
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                if(success){
                    self.delegate.modalDidFinished()
                    self.dismissViewControllerAnimated(true, completion: { () -> Void in
                       
                    })
                }else{
                    print("Bad login")
                    let alert = UIAlertController(title: "Error", message: "Invalid Login", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                    NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                        self.presentViewController(alert, animated: true, completion: nil)
                    })
                    
                }
            })
        }
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        print("seguaing")
        print(segue.destinationViewController)
    }


}
