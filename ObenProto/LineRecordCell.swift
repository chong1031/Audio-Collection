//
//  LineRecordCell.swift
//  ObenProto
//
//  Created by Will on 5/15/15.
//  Copyright (c) 2015 FFORM. All rights reserved.
//

import UIKit
import SwiftyJSON
import AVFoundation

let LineRecordCellHeight:CGFloat = 150.0



enum LineRecordStatus{
    case Recording
    case Stopped
    case Playback
   
    case Uploading
    case Success
    case Failed
}

protocol LineRecordDelegate{
    func lineStatus( status:LineRecordStatus, forRecordId:String )
}



class LineRecordCell: UITableViewCell {

    @IBOutlet weak var phraseLabel: UILabel!
    @IBOutlet weak var sampleButton: BorderedButton!
    @IBOutlet weak var recButton: BorderedButton!
    @IBOutlet weak var playbackButton: BorderedButton!
    
    
    var phrase:Phrase! = nil
    var currentPhrase:Phrase?
    var isRecording = false
    var isSaved = false
    
    var delegate:LineRecordDelegate?
    
    // MARK: init
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        recButton.onButtonTouch = self.actionRecord
        sampleButton.onButtonTouch = self.actionSample
        playbackButton.onButtonTouch = self.actionPlayback

        NSNotificationCenter.defaultCenter().addObserverForName("playStart", object: nil, queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
            self.updateUI(.Playback)
        }
        NSNotificationCenter.defaultCenter().addObserverForName("playStop", object: nil, queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
            self.updateUI(.Stopped)
        }
        NSNotificationCenter.defaultCenter().addObserverForName("recordStart", object: nil, queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
            self.updateUI(.Recording)
        }
        NSNotificationCenter.defaultCenter().addObserverForName("recordStop", object: nil, queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
            self.updateUI(.Stopped)
        }
        
    }
    
    func initValues(){
        isRecording = false
        isSaved = false

        updateIsSaved()
        

        updateUI(.Stopped)
    }
    
    // MARK: UI Events
    
    func actionRecord(sender:AnyObject, tag:Int){
        self.toggleRecording()
    }
    
    func actionSample(sender:AnyObject, tag:Int){
        self.updateUI(.Playback)
        print("Playback \(self.phrase.example)")
        if(AudioControl.shared.playRemoteUrl(NSURL(string: self.phrase.example)!) != true){
            let alert = UIAlertController(title: "Error", message: NSLocalizedString("example_download_fail", comment:""), preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { (action:UIAlertAction!) -> Void in
                
            }))
            UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(alert, animated: true, completion: nil)

        }
    }
    
    func actionPlayback(sender:AnyObject, tag:Int){
        self.updateUI(.Playback)
        if(!AudioControl.shared.playRemoteUrl(NSURL(string:self.phrase.recordingURL)!)){
            if let vc = self.delegate as? UIViewController{
                Utilities.alertWithMessage("Couldn't download file \(self.phrase.recordingURL)", title: "Playback Error", view: vc)
            }
            
        }
    }
    
    // MARK: UI Control
    
    func updateUI(status:LineRecordStatus){
        switch status{
        case .Playback:
            playbackButton.toggleEnabled(false)
            sampleButton.toggleEnabled(false)
            recButton.toggleEnabled(false)
            break
        case .Failed:
            playbackButton.toggleEnabled(false)
            break
        case .Success:
            playbackButton.toggleEnabled(true)
            break
        case .Recording:
            self.recButton.labelText = isRecording ? "STOP" : "REC"
            sampleButton.toggleEnabled(false)
            playbackButton.toggleEnabled(false)
            recButton.toggleEnabled(isRecording)
            self.phraseLabel.alpha = CGFloat(isRecording ? 1 : 0.5)
            break
        case .Stopped:
            recButton.labelText = "REC"
            
            playbackButton.toggleEnabled(isSaved)
            sampleButton.toggleEnabled(true)
            recButton.toggleEnabled(true)
            self.phraseLabel.alpha = 1
            break
        default:
            print("Noop")
        }
        
    }
    
    func updateIsSaved(){
        if !self.phrase.recordingURL.isEmpty {
            isSaved = true
        }
    }

    // MARK: Business
    
    func toggleRecording(){
        if(AudioControl.shared.recorder != nil){
            
            updateUI(.Uploading)
            
            print("Stop recording")
            let duration:NSTimeInterval = AudioControl.shared.stop()
            
            
            updateIsSaved()
            
            let data = AudioControl.shared.dataForSound()
            let upload = ObenUpload(name:"audioFile", filename: "blob.wav", data:data)
            isRecording = false
            var params:[String:AnyObject] = [
                "userId": ObenAPI.shared.userID,
                "recordId": phrase.recordID,
                "recordTime": duration
                //"avatarId": "456"
            ]
            
            if(Int(phrase.recordID)! == 1){
                let date = NSDate()
                params["startTime"] = date.timeIntervalSince1970
            }
            
            if(!ObenAPI.shared.avatarID.isEmpty){
                params["avatarId"] = ObenAPI.shared.avatarID
            }
            
            ObenAPI.shared.uploadAudioFile("ws/MorphingService/saveUserAvatar",
                config: params,
                upload: upload,
                success:{(res:SwiftyJSON.JSON?) in
                    
                    
                    
                    if(res?["UserAvatar"]["status"].string == "ERROR"){
                        self.isSaved = false
                        self.updateUI(.Failed)
                        self.delegate?.lineStatus(.Failed, forRecordId:self.phrase.recordID)
                    }else if(res?["UserAvatar"]["status"].string == "SUCCESS"){
                        self.isSaved = true
                        if let recordUrl = res?["UserAvatar"]["recordURL"].string{
                            self.phrase.recordingURL = recordUrl
                        }
                        
                        self.updateUI(.Success)

                        self.delegate?.lineStatus(.Success, forRecordId:self.phrase.recordID)
                        if let aID = res?["UserAvatar"]["avatarId"].stringValue {
                            ObenAPI.shared.avatarID = aID
                        }
                        

                        
                    }
                    
                    self.isRecording = false
                    self.updateUI(.Stopped)
                    
                }
            )
            
        }else{
            print("Start recording")
            AudioControl.shared.record()
            isRecording = true
            self.updateUI(.Recording)
            self.delegate?.lineStatus(.Recording, forRecordId:self.phrase.recordID)
        }
    }
}

