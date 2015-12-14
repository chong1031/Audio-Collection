//
//  AvatarCell.swift
//  ObenProto
//
//  Created by Will on 5/26/15.
//  Copyright (c) 2015 FFORM. All rights reserved.
//

import UIKit
import SWTableViewCell
import Haneke

let SMAvatarCellHeight = CGFloat(100.0)

class SMAvatarCell: SWTableViewCell {
    
    var avatar:Avatar! = nil
    var tvc:SMAvatarList?
    var index:NSIndexPath?
    
    @IBOutlet weak var img: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var subLabel: UILabel!
    @IBOutlet weak var morphButton: BorderedButton!
    @IBOutlet weak var morphRating: UIImageView!
    @IBOutlet weak var goldCup: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        morphButton.onButtonTouch = {(sender:UIButton, tag:Int) in
            //self.setSelected(true, animated: false)
            self.morphButton.onReset(self)
            self.tvc?.tableView.selectRowAtIndexPath(self.index!, animated: false, scrollPosition: UITableViewScrollPosition.None)
            self.tvc?.performSegueWithIdentifier("showMorph", sender: self.tvc!)
        }
        morphButton.isAnimated = false
        goldCup.image = ObenStyle.imageOfGoldCup.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
    }
    
    func setupUI(){
        nameLabel.text = avatar.name
        //img.image = ObenStyle.imageOfDefaultProfile
        subLabel.text = (avatar.canDelete == true ? "Your Avatar":"")
        morphRating.image = ObenStyle.imageOfMorphRating(rating: CGFloat(4-avatar.rating))
        //goldCup.hidden = (avatar.rating != 1)
        goldCup.tintColor = avatar.rating == 1 ? ObenStyle.goldColor : avatar.rating == 2 ? UIColor.lightGrayColor() : UIColor.clearColor()
//        let cache = Shared.dataCache
        self.img.hnk_setImageFromURL(NSURL(string:avatar.image)!)
        self.img.contentMode = UIViewContentMode.ScaleAspectFill
        self.img.clipsToBounds = true
        self.img.layer.cornerRadius = 25
        //self.img.autoresizingMask = UIViewAutoresizing.None
//
//        ImageManager.fetch(avatar.image,
//            progress: { (status: Double) in
//                
//            },success: { (data: NSData) in
//                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
//                    let image = UIImage(data: data)
//                    
//                    self.img.image = image
//
//                    
//                    self.img.setNeedsDisplay()
//                })
//                
//            }, failure: { (error: NSError) in
//                println("failed to get an image: \(error)")
//        })
        
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
}
