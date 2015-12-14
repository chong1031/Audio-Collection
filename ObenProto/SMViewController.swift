//
//  StreamingViewController.swift
//  ObenProto
//
//  Created by Will on 5/26/15.
//  Copyright (c) 2015 FFORM. All rights reserved.
//

import UIKit
import SwiftyJSON
import SWTableViewCell


class SMViewController: UIViewController {
    
    @IBOutlet weak var recButton: UIImageView!
    @IBOutlet weak var recOverlayBtn: UIButton!
    @IBOutlet weak var recordingTable: UITableView!
    @IBOutlet weak var targetMorphLabel: UILabel!
    @IBOutlet weak var textEntry: UITextView!
    @IBOutlet weak var morphButton: BorderedButton!
    @IBOutlet weak var textLimit: UILabel!
    
    @IBOutlet weak var voiceView: UIView!
    @IBOutlet weak var textView: UIView!
    
    
    
    var progress:ObenProgress?
    var tableData = [MorphResult]()
    var avatar:Avatar?
    var fastSwitch:UISwitch?
    
    let modes = ["Similarity","Clarity"]
    let languages = [ "KO":"Korean", "JA": "Japanese", "ZH": "Chinese" ]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.title = ""
        self.view.clipsToBounds = true
        progress = ObenProgress(view:self.navigationController!.view)
        
        recordingTable.dataSource = self
        recordingTable.delegate = self
        recordingTable.estimatedRowHeight = MorphRecordingCellHeight
        recordingTable.rowHeight = UITableViewAutomaticDimension

        
        recButton.image = ObenStyle.imageOfRecordButton(amount: 0)
        
        let barButton = UIBarButtonItem(image: ObenStyle.imageOfGear, style: UIBarButtonItemStyle.Plain, target: self, action: "openSettingsSheet")
        self.navigationItem.setRightBarButtonItem(barButton, animated: true)

        self.voiceView.backgroundColor = UIColor.clearColor()
        self.recOverlayBtn.backgroundColor = UIColor.clearColor()
        self.textView.backgroundColor = UIColor.clearColor()
        self.textView.alpha = 0
        self.textView.hidden = true
        self.voiceView.hidden = false
        self.textLimit.text = "1000"
        
        self.textEntry.delegate = self
        self.morphButton.onButtonTouch = { (sender:AnyObject, num:Int)->() in
            self.textMorph()
        }
        
    }
    
    @IBAction func typeChanged(sender: UISegmentedControl) {
        
        let index = sender.selectedSegmentIndex
        CGRectGetWidth(self.view.bounds)
        
        
        if(index != 1){
            self.textEntry.resignFirstResponder()
        }else{
            self.textEntry.becomeFirstResponder()
        }
        
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.voiceView.alpha = (index == 0 ? 1.0 : 0)
            self.voiceView.hidden = (index != 0)
            self.textView.alpha = (index == 1 ? 1.0 : 0)
            self.textView.hidden = (index != 1)
        })
        
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        refreshTable()
        self.targetMorphLabel.text = ""
        
        self.title = self.avatar?.name
        
        updateUI()
        
        ObenAPI.shared.onSocketOpen.listen(self, callback: {
            self.log("Connection opened, wait for ready msg")
            
            //ObenAPI.shared.socketWriteData("test data".dataUsingEncoding(NSUTF8StringEncoding)!, isSocketio: self.socketType.selectedSegmentIndex == 0)
        })
        ObenAPI.shared.onSocketClose.listen(self, callback: {
            self.log("Connection closed")
        })
        
        ObenAPI.shared.onSocketReady.listen(self, callback:{
            print("Socket ready, write data")
            self.log("Socket ready, starting recording stream")
            
            let start:JSON = [ "action": "STREAM_DATA",
                "avatarId": self.avatar!.id,
                "userId": "\(ObenAPI.shared.userID)"
            ]
            
            if let string = start.rawString(){
                ObenAPI.shared.socketWriteString(string)
            }
            
            self.log("Audio Source is Microphone")
            AudioControl.shared.onRecordingData.removeAllListeners()
            AudioControl.shared.onRecordingData.listen(self){ (data:NSData) in
                print("Got data \(data.length)")
                ObenAPI.shared.socketWriteData(data)
            }
            AudioControl.shared.record()
            
        })
        
        ObenAPI.shared.onSocketAck.listen(self, callback:{ (morphId:String) in

            self.progress?.setProgAndLabel(0.25, text: "Processing Result")
            
            self.log("Received ACK!, closing...")
            self.log("MorphID: \(morphId)")
            ObenAPI.shared.closeSocket()
            
            ObenAPI.shared.morphStatus(morphId, avatarId:self.avatar!.id, complete: { (morph:MorphResult?, message:String?, error:String?) -> Void in
                if let err = error{
                    self.progress?.hideProgressWithDelay(false)
                    Utilities.alertWithMessage(err, title: "Error", view: self)
                }else{
                    self.downloadMorph(morph)
                }
                
                
            })
        })
        
        ObenAPI.shared.onMorphStatusPing.removeAllListeners()
        ObenAPI.shared.onMorphStatusPing.listen(self){ (message:String,status:String,prog:Int) in
            let p = CGFloat(prog)/100
          
            self.progress?.setProgAndLabel(p, text: message)
        }
        
        AudioControl.shared.onRecordingMeterUpdate.listen(self){ (avg:Float, low:Float, high:Float) in
            let newLow = abs(low)
            let newHigh = newLow + high
            let newAvg = newLow + avg
            let prog = max(0,min(1,abs( newAvg / newHigh )))
            print("METER: \(newAvg), \(newLow)/\(newHigh)  -> \(prog)")
            self.recButton.image = ObenStyle.imageOfRecordButton(amount: CGFloat(prog))
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        AudioControl.shared.stopPlayback()
        AudioControl.shared.onRecordingData.removeListener(self)
        ObenAPI.shared.onMorphStatusPing.removeAllListeners()
        
        ObenAPI.shared.onSocketOpen.removeListener(self)
        ObenAPI.shared.onSocketClose.removeListener(self)
        ObenAPI.shared.onSocketReady.removeListener(self)
        ObenAPI.shared.onSocketAck.removeListener(self)
        ObenAPI.shared.onSocketError.removeListener(self)
        ObenAPI.shared.onSocketWriteReady.removeListener(self)
        ObenAPI.shared.onSocketWriting.removeListener(self)
        
        ObenAPI.shared.closeSocket()
    }
    
    
    func openSettingsSheet(){
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let msVC = sb.instantiateViewControllerWithIdentifier("morphSettingsVC") as! MorphSettingsViewController
        msVC.providesPresentationContextTransitionStyle = true
        msVC.definesPresentationContext = true
        msVC.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
        msVC.svc = self
        self.presentViewController(msVC, animated: false, completion: nil)
        
    }
    
    func updateUI(){
        
        self.targetMorphLabel.text = Preferences.shared.voiceStreaming ? "Fast" : "Standard"
        if(!Preferences.shared.voiceStreaming){
            self.targetMorphLabel.text = "\(self.targetMorphLabel.text!) - \(modes[Preferences.shared.streamingMethod])"
        }
        var btnText = "\(modes[Preferences.shared.streamingMethod]) Morph "
        if let lang = languages[Preferences.shared.ttsLanguage]{
            btnText = "\(btnText)in \(lang)"
        }else{
            btnText = "\(btnText)Text"
        }
        self.morphButton.labelText = btnText
    }
    
    
    @IBAction func tapStart(sender: AnyObject) {
        
        recButton.image = ObenStyle.imageOfRecordButton(amount: 0.5)
        
        if(Preferences.shared.voiceStreaming){
            ObenAPI.shared.openSocket()
        }else{
            AudioControl.shared.record()
        }
        
    }
    
    @IBAction func tapStop(sender: AnyObject) {
        stopStreaming()
    }
    
    func stopStreaming(){
        AudioControl.shared.stop()
        recButton.image = ObenStyle.imageOfRecordButton(amount: 0)
        self.progress?.setProgAndLabel(0, text: "Waiting for receipt")
        
        if(Preferences.shared.voiceStreaming){
            ObenAPI.shared.socketWriteString("{\"action\":\"STREAM_END\"}")
        }else{
            self.uploadMorph()
        }
        
    }
    
    func log(msg:String!){
        
        //statusText.text = "\(msg)\n\(statusText.text)"
        print(msg)
        
    }
    
    func refreshTable(){
        print("refresh")
        
        ObenAPI.shared.getAvatarMorphs(self.avatar!.id, success: { (data) -> Void in
            self.tableData = data
            dispatch_async(dispatch_get_main_queue(), {
                self.recordingTable.reloadData()
            })
        })
        
        
    }
    func addNewRecording(recording:MorphResult){
        tableData.insert(recording, atIndex: 0)
        self.recordingTable.beginUpdates()
        self.recordingTable.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Top)
        self.recordingTable.endUpdates()
    }
    
    func uploadMorph(){
        let upload = ObenUpload(name:"audioFile", filename: "blob.wav", data:AudioControl.shared.dataForSound())
        ObenAPI.shared.uploadAudioFile("ws/MorphingService/morphRecording", config: [
            "userId": ObenAPI.shared.userID,
            "avatarId": self.avatar!.id,
            "mode": Preferences.shared.streamingMethod
            ],
            upload: upload,
            success:{(res:SwiftyJSON.JSON?) in
                print(res?["Morph"])
                if(res?["Morph"]["status"].string == "ERROR"){
                    print("Error upload")
                    let msg = res?["Morph"]["message"].stringValue
                    let alert = UIAlertController(title: "Error", message: msg, preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                    dispatch_async(dispatch_get_main_queue(), {
                        self.progress?.showProgress(false)
                    })
                }else if(res?["Morph"]["status"].string == "PENDING"){
                    
                    
                    if let morphValue = res?["Morph"]["morphId"]{
                        let morphID = safeStr(morphValue.stringValue)
                        print("Start polling for status")
                        ObenAPI.shared.morphStatus(morphID, avatarId:self.avatar!.id, complete: { (morph:MorphResult?, message:String?, error:String?) -> Void in
                            if let err = error{
                                self.progress?.hideProgressWithDelay(false)
                                Utilities.alertWithMessage(err, title: "Error", view: self)
                            }else{
                                self.downloadMorph(morph)
                            }
                            
                        })
                    }else{
                        print("No morph id, can't poll")
                    }
                    
                    
                    
                }
                
            }
        )
    }
    
    func downloadMorph(morph:MorphResult?){
        self.progress?.setProgAndLabel(1.0, text: "Received!")
        self.progress?.hideProgressWithDelay(true)
        print("Download \(morph?.url)")

        if let m = morph{
            self.addNewRecording(m)
        }

    }
    
    
    func textMorph(){
        self.textEntry.resignFirstResponder()
        self.progress?.setProgAndLabel(0, text: "Connecting")
        
        ObenAPI.shared.textToSpeechWithAvatar(self.avatar!.id, text:self.textEntry.text, lang:Preferences.shared.ttsLanguage, mode:Preferences.shared.streamingMethod, complete: { (morphID:String?, message:String?) -> Void in
            if let msg = message{
                self.progress?.setProgAndLabel(0.05, text: msg)
            }
            if let id = morphID{
                ObenAPI.shared.morphStatus(id, avatarId:self.avatar!.id, complete: { (morph:MorphResult?, message:String?, error:String?) -> Void in
                    if let e = error{
                        Utilities.alertWithMessage(e, title: "Error", view: self)
                        self.progress?.hideProgressWithDelay(true)
                    }else{
                        self.downloadMorph(morph)
                    }
                    
                })
            }else{
                print("instant error")
                let msg = message != nil ? message! : "Unknown Error"
                Utilities.alertWithMessage(msg, title: "Error", view: self)
                self.progress?.hideProgressWithDelay(true)
            }
            
            
        })
    }
}


extension SMViewController: UITableViewDataSource{
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }

}

extension SMViewController: UITableViewDelegate{
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let row = tableData[indexPath.row] as MorphResult
        print("Should play \(row.url)")
        AudioControl.shared.playRemoteUrl(NSURL(string: row.url)!)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("morphRecordingCell", forIndexPath: indexPath) as! MorphRecordingTableViewCell
        let row = tableData[indexPath.row] as MorphResult

        cell.transcription.text = row.transcription
        cell.statusLabel.text = "\(row.morphId) - \(row.type) / \(row.mode)"
        let rightButtons = NSMutableArray()
        let leftButtons = NSMutableArray()
        
        rightButtons.sw_addUtilityButtonWithColor(UIColor.redColor(), title: "Delete")
        rightButtons.sw_addUtilityButtonWithColor(ObenStyle.obenBlue, title: "More ...")
        leftButtons.sw_addUtilityButtonWithColor(ObenStyle.obenBlue, title: "Share")

        cell.rightUtilityButtons = rightButtons as [AnyObject]
        cell.leftUtilityButtons = leftButtons as [AnyObject]
        cell.delegate = self
        cell.morph = row
        

        let tap = UITapGestureRecognizer(target: self, action: "handleDetailPlay:")
        cell.playImage.addGestureRecognizer(tap)
        cell.playImage.tag = Int(row.morphId)!
        return cell
    }
    
    func handleDetailPlay(gesture:UILongPressGestureRecognizer){
        print("detail press \(gesture)")
        print(gesture.view?.tag)
        if( gesture.state == .Ended){
            handleMoreForMorphID(gesture.view!.tag)
        }
        
    }
    
    func handleMoreForMorphID(id:Int){
        let result = tableData.filter{ $0.morphId == "\(id)" }
        if let morph = result.first{
            let sheet = UIActionSheet(title: "Morph #\(morph.morphId) Details", delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Play Original", "Play Morphed", "Modify ...")
            sheet.tag = Int(morph.morphId)!
            sheet.showInView(self.view)
        }
        
    }
    
}

extension SMViewController: UIActionSheetDelegate{
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int){
        print("Tapped \(buttonIndex)")
        let result = tableData.filter{ $0.morphId == "\(actionSheet.tag)" }
        if let morph = result.first{
            switch(buttonIndex){
            case 1: AudioControl.shared.playRemoteUrl(NSURL(string: morph.originalUrl)!)
            case 2: AudioControl.shared.playRemoteUrl(NSURL(string: morph.url)!)
            case 3:
                let vc = self.storyboard!.instantiateViewControllerWithIdentifier("modifyVC") as! ModifyMorphViewController
                self.providesPresentationContextTransitionStyle = true
                vc.modalPresentationStyle = .OverCurrentContext
                vc.morph = morph
                self.presentViewController(vc, animated: false, completion: nil)
            default: break
            }
        }
        
    }
}


extension SMViewController: SWTableViewCellDelegate{
    func swipeableTableViewCell(cell: SWTableViewCell!, didTriggerLeftUtilityButtonWithIndex index: Int){
        if let row = cell as? MorphRecordingTableViewCell{
            switch(index){
            case 0:
                if let remoteUrl = NSURL(string:row.morph.url),
                       localUrl = Utilities.urlForPath("shares/\(row.morph.avatarId)-\(row.morph.morphId).wav"){
                        if( Utilities.downloadFromRemoteURL(remoteUrl, toFileURL: localUrl) ){
                            let shareCopy = "Check out this morph recording with the voice of \(self.avatar!.name)"
                            let objectsToShare = [shareCopy, localUrl]

                            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                            activityVC.excludedActivityTypes = [UIActivityTypeMessage, UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll]
                            activityVC.setValue("My Oben recording of\(self.avatar!.name)", forKey: "subject")
                            
                            self.presentViewController(activityVC, animated: true, completion: nil)
                        }else{
                            Utilities.alertWithMessage("Couldn't get morph download.", title: "Error", view: self)
                        }
                        
                }
                
            default:
                print("Unknown right utility btn")
            }
            cell.hideUtilityButtonsAnimated(true)
        }
    }
    func swipeableTableViewCell(cell: SWTableViewCell!, didTriggerRightUtilityButtonWithIndex index: Int){
        if let row = cell as? MorphRecordingTableViewCell{

            switch(index){
            case 0:
                ObenAPI.shared.deleteMorph(row.morph.morphId, completion: { (success:Bool) -> () in
                    if(success){

                        if let indexPath = self.recordingTable.indexPathForCell(cell){

                            dispatch_async(dispatch_get_main_queue(), {
                                self.recordingTable.beginUpdates()
                                self.recordingTable.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Top)
                                self.tableData.removeAtIndex(indexPath.row)
                                self.recordingTable.endUpdates()
                            })
                            
                        }
                        
                    }else{
                        Utilities.alertWithMessage("Couldn't delete morph", title: "Error", view: self)
                    }
                })
            case 1:
                handleMoreForMorphID(row.playImage.tag)
            default:
                print("Unknown right utility btn")
            }
        }
        cell.hideUtilityButtonsAnimated(true)
    }
}

extension SMViewController: UITextViewDelegate{
    
    func textViewDidChange(textView: UITextView) {

        self.textLimit.text = "\(1000 - self.textEntry.text.characters.count)"
        
        if(self.textEntry.text.characters.count > 0){
            self.morphButton.toggleEnabled(true)
        }else{
            self.morphButton.toggleEnabled(false)
        }
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n"{
            textView.resignFirstResponder()
            textMorph()
            return false
        }
        
        let newLength = textView.text!.characters.count + text.characters.count - range.length
        
        return newLength <= 1000
    }
    
}
