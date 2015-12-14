//
//  ProfileViewController.swift
//  ObenProto
//
//  Created by Will on 5/15/15.
//  Copyright (c) 2015 FFORM. All rights reserved.
//

import UIKit

struct ProfileTableRow{
    var title:String
    var value:String
}

class ProfileViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var setupButton: BorderedButton!
    
    var tableData = [ProfileTableRow]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupButton.onButtonTouch = {(sender:UIButton, tag:Int) in
            self.performSegueWithIdentifier("showAvatarSetup", sender: self)
        }
        
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        let right = UIBarButtonItem(title: "Logout", style: UIBarButtonItemStyle.Plain, target: self, action: "actionLogout")
        self.navigationItem.rightBarButtonItem = right

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        refreshTable()
        
    }


    func refreshTable(){
        print("refresh")
        tableData.removeAll(keepCapacity: false)
        tableData.append(ProfileTableRow(title:"User ID", value:ObenAPI.shared.userID))
        tableData.append(ProfileTableRow(title:"Avatar ID", value:ObenAPI.shared.avatarID))
        tableData.append(ProfileTableRow(title:"Email", value:Preferences.shared.userEmail))
        tableView.reloadData()
    }
    
    func actionLogout(){
        if let tbc = self.tabBarController as? FFTabBarController{
            tbc.logout()
        }
    }
}

extension ProfileViewController: UITableViewDataSource{
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
}

extension ProfileViewController: UITableViewDelegate{
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("infoCell", forIndexPath: indexPath)
        let row = tableData[indexPath.row] as ProfileTableRow
        cell.textLabel?.text = row.title
        cell.detailTextLabel?.text = row.value
        
        return cell
    }
}