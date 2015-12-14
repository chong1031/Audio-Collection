//
//  MorphRecordingTableViewCell.swift
//  ObenProto
//
//  Created by Will on 7/27/15.
//  Copyright (c) 2015 FFORM. All rights reserved.
//

import UIKit
import SWTableViewCell

let MorphRecordingCellHeight:CGFloat = 80.0

class MorphRecordingTableViewCell: SWTableViewCell {

    
    @IBOutlet weak var transcription: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var playImage: UIImageView!
    
    var morph:MorphResult!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.playImage.userInteractionEnabled = true
        self.playImage.contentMode = UIViewContentMode.TopRight
        self.playImage.clipsToBounds = true
        self.playImage.image = ObenStyle.imageOfPlay
        let swipe = UISwipeGestureRecognizer()
        self.playImage.addGestureRecognizer(swipe)
        let long = UILongPressGestureRecognizer()
        self.playImage.addGestureRecognizer(long)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
