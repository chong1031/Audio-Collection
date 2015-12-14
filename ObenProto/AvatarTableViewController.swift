//
//  AvatarTableViewController.swift
//  ObenProto
//
//  Created by Will on 5/15/15.
//  Copyright (c) 2015 FFORM. All rights reserved.
//

import UIKit

class AvatarTableViewController: UITableViewController  {
    var phrases = [Phrase]()
    var previousRecordings = [String:AnyObject]()
    var tableData = [Phrase]()
    var maxPhrases = 0
    var initialized = false
    
    @IBOutlet weak var progressView: UIProgressView!
    //var HUD:M13ProgressHUD?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        //self.tableView.rowHeight = LineRecordCellHeight
        tableView.estimatedRowHeight = LineRecordCellHeight
        tableView.rowHeight = UITableViewAutomaticDimension

        
        self.navigationItem.setHidesBackButton(true, animated: false)
        let left = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: self, action: "actionCancel")
        self.navigationItem.leftBarButtonItem = left
        
//        var prog = M13ProgressViewRing()
//        prog.showPercentage = false
//        prog.indeterminate = true
//        HUD = M13ProgressHUD(progressView: prog)
//        HUD?.progressViewSize = CGSizeMake(60, 60)
//        HUD?.animationPoint = CGPointMake( UIScreen.mainScreen().bounds.size.width/2, UIScreen.mainScreen().bounds.size.height/2)
//        HUD?.maskType = M13ProgressHUDMaskTypeGradient
//        HUD?.shouldAutorotate = true
//        self.view.addSubview(HUD!)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("disableScroll"), name: "playStart", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("disableScroll"), name: "recordStart", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("enableScroll"), name: "playStop", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("enableScroll"), name: "recordStop", object: nil)
        
        
        
        refreshPhrases()
    }
    
    func enableScroll(){
        tableView.scrollEnabled = true
    }
    func disableScroll(){
        tableView.scrollEnabled = false
    }
    

    
    func refreshPhrases(){
        print("Refresh Phrases")
        
        ObenAPI.shared.getPreviousAvatarRecordings(ObenAPI.shared.avatarID, success: { (data) -> Void in
            self.previousRecordings = data
            ObenAPI.shared.getPhrases({ (data:[Phrase]) -> Void in
                dispatch_async(dispatch_get_main_queue(), {
                    self.tableData = [Phrase]()
                    self.phrases = [Phrase]()
                    self.maxPhrases = data.count
                    var completedPhrases = 0
                    for phrase:Phrase in data as [Phrase]{
                        var thisPhrase = phrase
                        if let recordedPhrase = self.previousRecordings["record\(phrase.recordID)"] as? String{
                            thisPhrase.recordingURL = recordedPhrase
                            self.tableData.insert(thisPhrase, atIndex: 0)
                            completedPhrases += 1
                        }else{
                            self.phrases.append(phrase)
                        }
                        
                    }
                    
                    self.progressView.setProgress(Float(completedPhrases/self.maxPhrases), animated: true)
                    self.tableView.reloadData()
                    self.actionAddItem()
                })
            })
        })
        
        
    }
    
    func actionAddItem(){
        if(phrases.count > 0){
            let p = self.phrases.removeAtIndex(0)
            let progress = (Float(maxPhrases-phrases.count)/Float(maxPhrases))
            tableData.insert(p, atIndex: 0)
            self.progressView.setProgress(progress, animated: true)
            self.tableView.beginUpdates()
            
            self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Top)
            self.tableView.endUpdates()
        }else{
            let alert = UIAlertController(title: "Done", message: NSLocalizedString("avatar_ready_to_save", comment:""), preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { (action:UIAlertAction!) -> Void in
                
            }))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
        if(maxPhrases - phrases.count > 3){
            if(self.navigationItem.rightBarButtonItem == nil){
                let right = UIBarButtonItem(title: "Save Avatar", style: UIBarButtonItemStyle.Plain, target: self, action: "actionSaveAvatar")
                self.navigationItem.setRightBarButtonItem(right, animated: true)
            }
            
        }
        
    }
    
    func actionCancel(){
        var cancelMessage = NSLocalizedString("avatar_early_cancel", comment:"")
        if(ObenAPI.shared.avatarID.isEmpty){
            cancelMessage = "All phrases will be deleted unless you record at least 3 phrases and save"
        }
        let alert = UIAlertController(title: "Cancel Avatar", message: cancelMessage, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Yes, Cancel", style: UIAlertActionStyle.Default, handler: { (action:UIAlertAction!) -> Void in
            self.navigationController?.popViewControllerAnimated(true)
        }))
        alert.addAction(UIAlertAction(title: "Keep Recording", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion:nil)
    }
    
    func actionSaveAvatar(){
        print("Save avatar")

//        HUD?.progressView.indeterminate = true
//        HUD?.status = "Saving"
//        HUD?.show(true)
        JHProgressHUD.sharedHUD.showInView(self.view, withHeader: "Saving", andFooter: nil)
        
        self.navigationController?.navigationBar.hidden = true
        self.navigationController?.navigationItem.title = "Processing"
        self.tableView.scrollEnabled = false
        
        ObenAPI.shared.saveAvatar({ (success:Bool, message:String) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                //self.HUD?.hide(true)
                JHProgressHUD.sharedHUD.hide()
                self.navigationController?.navigationBar.hidden = false
                self.navigationController?.navigationItem.title = ""
                self.tableView.scrollEnabled = true
                if(!success){
                    //NSLocalizedString("avatar_process_failed", comment:"")
                    let alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                }else{
                    self.clearRecordedPhrases()
                    let alert = UIAlertController(title: "Processing", message: "Your avatar is being processed. It will appear in the avatar list when completed.", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { (action:UIAlertAction!) -> Void in
                        self.navigationController?.popViewControllerAnimated(true)
                    }))
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            })
        })

    }
    
    func clearRecordedPhrases(){
        AudioControl.shared.cleanFiles();
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        //self.tabBarController?.setTabBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        //self.tabBarController?.setTabBarHidden(false, animated: true)
    }
 
    // MARK: Scroll View Delegate
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        //super.scrollViewDidScroll(scrollView)
        //let bottom = CGRectGetMaxY(self.view.frame)
        var frame = self.progressView.frame
        frame.origin.x = 0
        frame.origin.y = self.tableView.contentOffset.y + CGRectGetHeight(self.tableView.bounds) - CGRectGetHeight(self.progressView.bounds)
        
        self.progressView.frame = frame
        
        self.tableView.bringSubviewToFront(self.progressView)
        print(frame)
    }
    
    // MARK: TableView Data Source Delegate
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    // MARK: TableView Delegate
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! LineRecordCell
        
        cell.phrase = self.tableData[indexPath.row] as Phrase
        cell.phraseLabel.text = cell.phrase.phrase
        cell.initValues()
        cell.delegate = self
        
        return cell
    }
}


extension AvatarTableViewController: LineRecordDelegate{
    func lineStatus( status:LineRecordStatus, forRecordId:String ){
        if( status == LineRecordStatus.Success ){
            if let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? LineRecordCell{
                if( cell.phrase.recordID == forRecordId){
                    self.actionAddItem()
                }
                
            }
            
        }
    }
}
