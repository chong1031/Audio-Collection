//
//  MorphTableViewController.swift
//  ObenProto
//
//  Created by Will on 2/27/15.
//  Copyright (c) 2015 FFORM. All rights reserved.
//

import UIKit
import SWTableViewCell

class SMAvatarList: UITableViewController {
    
    
    var tableData = [Avatar]()
    var initialized = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.rowHeight = SMAvatarCellHeight
        
        let right = UIBarButtonItem(title: "Logout", style: UIBarButtonItemStyle.Plain, target: self, action: "actionLogout")
        self.navigationItem.rightBarButtonItem = right
        
        let refresh = UIRefreshControl()
        refresh.tintColor = ObenStyle.obenBlue
        refresh.addTarget(self, action: "refreshAvatars", forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl = refresh
    }
    
    func actionLogout(){
        if let tbc = self.tabBarController as? FFTabBarController{
            tbc.logout()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        print("SM viewWillAppear \(initialized)")
        self.tabBarController?.setTabBarHidden(false, animated: true)

    }
    
    func refreshAvatars(){
        print("Refresh avatars")
        
        ObenAPI.shared.getAvatars({(data:Array<Avatar>) in
            self.tableData = data
            dispatch_async(dispatch_get_main_queue(), {
                
                print("Back to table")
                
                self.refreshControl?.endRefreshing()
                
                self.tableView.reloadData()
                self.tableView.setNeedsDisplay()
            })
            
            
        })
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! SMAvatarCell
        _ = self.tableData[indexPath.row] as Avatar
        
        cell.avatar = self.tableData[indexPath.row] as Avatar
        cell.tvc = self
        cell.index = indexPath
        cell.setupUI()
        
        let rightButtons = NSMutableArray()
        
        rightButtons.sw_addUtilityButtonWithColor(UIColor(red:1.000, green:0.372, blue:0.104, alpha:1.0), title: "Clean")
        if(cell.avatar.canDelete){
            rightButtons.sw_addUtilityButtonWithColor(UIColor.redColor(), title: "Delete")
        }
        
        
        cell.rightUtilityButtons = rightButtons as [AnyObject]
        cell.delegate = self
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("showMorph", sender: self)
    }
    
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //self.tabBarController?.setTabBarHidden(true, animated: true)
        print("Preparet for selection")
        if let indexPath:NSIndexPath = self.tableView.indexPathForSelectedRow{
            let ava:Avatar = tableData[indexPath.row]
            if let dvc = segue.destinationViewController as? SMViewController{
                dvc.avatar = ava
            }
        }
        
    }
    
    
}


extension SMAvatarList: SWTableViewCellDelegate{
    func swipeableTableViewCell(cell: SWTableViewCell!, didTriggerRightUtilityButtonWithIndex index: Int){
        if let row = cell as? SMAvatarCell{
            switch(index){
            case 0:
                ObenAPI.shared.deleteAllMorphs(row.avatar.id, completion: { (success:Bool) -> () in
                    if(success){
                        Utilities.alertWithMessage("All morphs removed.", title: "Success", view: self)
                    }else{
                        Utilities.alertWithMessage("Couldn't delete morphs", title: "Error", view: self)
                    }
                })
            case 1:
                ObenAPI.shared.deleteAvatar(row.avatar, complete:{() -> Void in
                    if let indexPath = self.tableView.indexPathForCell(cell){
                        dispatch_async(dispatch_get_main_queue(), {
                            self.tableView.beginUpdates()
                            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Top)
                            self.tableData.removeAtIndex(indexPath.row)
                            self.tableView.endUpdates()
                        })
                    }
                })
            default:
                print("Unknown right utility btn")
            }
        }
        cell.hideUtilityButtonsAnimated(true)
    }
}