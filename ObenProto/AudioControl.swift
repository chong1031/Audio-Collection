//
//  AudioControl.swift
//  ObenProto
//
//  Created by Will on 2/26/15.
//  Copyright (c) 2015 FFORM. All rights reserved.
//

import UIKit
import AVFoundation
import Signals

struct AudioStatus{
    var play:Bool = false
    var stop:Bool = false
    var upload:Bool = false
}

protocol AudioControlDelegate{
    func playerDidStartPlaying()
    func playerDidFinishPlaying(success:Bool)
    func recorderDidStartRecording()
    func recorderDidFinishRecording(success:Bool)
}

class AudioControl: NSObject {
    
    var soundFileURL:NSURL?
    var soundFilePath:String?
    var recorder: AVAudioRecorder!
    var player:AVAudioPlayer!
    var _fileDescriptor:CInt!
    var _dispatch_source:dispatch_source_t!
    private var _meterTimer:NSTimer!
    
    let onRecordingData = Signal<NSData>()
    let onRecordingMeterUpdate = Signal<(avg:Float,min:Float,max:Float)>()
    
    var delegate:AudioControlDelegate?
    
    var meterLow:Float = 100
    var meterHigh:Float = -100
    
    class var shared: AudioControl {
        struct Static {
            static let instance: AudioControl = AudioControl()
        }
        Static.instance.initialze()
        return Static.instance
    }
    
    func initialze(){
        let currentFileName = "recording-temp.wav"
        var dirPaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let docsDir: AnyObject = dirPaths[0]
        soundFilePath = docsDir.stringByAppendingPathComponent(currentFileName)
        soundFileURL = NSURL(fileURLWithPath: soundFilePath!)
    }
    
    func dataForSound() -> NSData{
        let soundData = NSData(contentsOfURL: soundFileURL!)!
        return soundData
    }
    
    func urlForSound() -> NSURL{
        return soundFileURL!
    }
    
    func record() -> AudioStatus{
        var status = AudioStatus()
        status.play = true
        if player != nil && player.playing {
            player.stop()
            delegate?.playerDidFinishPlaying(false)
        }

        
        if recorder == nil {
            print("recording. recorder nil")
            status.play = false
            status.stop = true
            recordWithPermission(true)
            return status
        }
        
        if recorder != nil && recorder.recording {
            print("pausing")
            recorder.pause()
            
        } else {
            print("recording")
            status.play = false
            status.stop = true
            recordWithPermission(false)
        }
        return status
    }
    
    func stop() -> NSTimeInterval{
        if recorder == nil{
            return NSTimeInterval(0)
        }
        let duration = recorder.currentTime
        print("stopped at \(recorder.currentTime)")
        
        recorder.stop()
        if(self._meterTimer != nil){
            self._meterTimer.invalidate()
        }
        

        let session:AVAudioSession = AVAudioSession.sharedInstance()
        do{
            try session.setActive(false)
        }catch{
            print("could not make session inactive")
        }
        recorder = nil
        return duration
    }
    
    func stopPlayback(){
        if(self.player != nil && self.player.playing){
            delegate?.playerDidFinishPlaying(false)
            self.player.stop()
        }
    }
    
    func play( urlToPlay:NSURL? ){
        print("playing")
        var url = NSURL(string:"")
        if(urlToPlay != nil){
            url = urlToPlay!
        }else{
            url = soundFileURL
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName("playStart", object: nil)
        
        if player != nil && player.playing{
            delegate?.playerDidFinishPlaying(false)
            NSNotificationCenter.defaultCenter().postNotificationName("playStop", object: nil)
        }
        // recorder might be nil
        // self.player = AVAudioPlayer(contentsOfURL: recorder.url, error: &error)
        do{
            try self.player = AVAudioPlayer(contentsOfURL: url!)
            self.setSessionPlayback()
            player.delegate = self
            player.prepareToPlay()
            player.volume = 1.0
            player.play()
        }catch{
            
        }
        

    }
    
    func playRemoteUrl( url:NSURL )->Bool{
        let manager = NSFileManager.defaultManager()
        let soundData = NSData(contentsOfURL: url)
        if let filePath:String = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first{
            let file = "\(filePath)/example.wav"
            if(manager.fileExistsAtPath(file)){
                print("Removing old file")
                do{
                    try manager.removeItemAtPath(file)
                }catch{
                    print("Couldn't remove file")
                }
            }
            if((soundData?.writeToFile(file, atomically: true)) == true){
                AudioControl.shared.play(NSURL(fileURLWithPath: file))
                return true
            }else{
                print("Couldn't write file \(soundData)")
                NSNotificationCenter.defaultCenter().postNotificationName("playStop", object: nil)
            }
            
            
        }
        return false
        
        
    }

    func setupRecorder() {

        
        let filemanager = NSFileManager.defaultManager()
        if filemanager.fileExistsAtPath(soundFilePath!) {
            // probably won't happen. want to do something about it?
            print("sound exists")
            do{
                try filemanager.removeItemAtURL(soundFileURL!)
            }catch{
                // noop
            }
        }
        
        let recordSettings = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVEncoderAudioQualityKey : AVAudioQuality.High.rawValue,
            AVEncoderBitRateKey : 16000,
            AVNumberOfChannelsKey: 1,
            AVSampleRateKey : 16000.0,
            AVLinearPCMBitDepthKey: 16
        ]
        
        do {
            recorder = try AVAudioRecorder(URL: soundFileURL!, settings: recordSettings as! [String : AnyObject])
            recorder.delegate = self
            recorder.meteringEnabled = true
            recorder.prepareToRecord() // creates/overwrites the file at soundFileURL
        } catch{
            recorder = nil
        }
    }
    
    func recordWithPermission(setup:Bool) {
        let session:AVAudioSession = AVAudioSession.sharedInstance()
        // ios 8 and later
        if (session.respondsToSelector("requestRecordPermission:")) {
            AVAudioSession.sharedInstance().requestRecordPermission({(granted: Bool)-> Void in
                if granted {
                    print("Permission to record granted")
                    self.setSessionPlayAndRecord()
                    if setup {
                        self.setupRecorder()
                    }
                    self.recorder.record()
                    var buffer = [Int8](count: Int(PATH_MAX), repeatedValue: 0)

                    self.soundFileURL!.getFileSystemRepresentation(&buffer, maxLength: buffer.count)
                    
                    self._fileDescriptor = open(buffer, O_EVTONLY)
                    let defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
                    self._dispatch_source = dispatch_source_create(
                            DISPATCH_SOURCE_TYPE_VNODE,
                            UInt(self._fileDescriptor),//self._fileDescriptor,
                            DISPATCH_VNODE_WRITE,
                            defaultQueue
                    )
                    var lastSize:Int = 0
                    
                    dispatch_source_set_event_handler(self._dispatch_source) {

                        if let contents = NSFileManager.defaultManager().contentsAtPath(self.soundFileURL!.path!){
                            let newSize = contents.length - lastSize
                            let newData = NSData(data: contents.subdataWithRange(NSRange(location: lastSize, length: newSize)))
                            
                            lastSize = contents.length
                            //print("Added: \(lastSize)  Total:\(contents.length)")
                            //print(newData)
                            dispatch_async(dispatch_get_main_queue(), {
                                self.onRecordingData.fire(newData)
                            })
                            
                        }
                        
                    }
                    
                    dispatch_resume(self._dispatch_source)
                    
                    self._meterTimer = NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: "meterUpdate", userInfo: nil, repeats: true)
                    
                    self.delegate?.recorderDidStartRecording()
                    NSNotificationCenter.defaultCenter().postNotificationName("recordStart", object: nil)
                } else {
                    print("Permission to record not granted")
                }
            })
        } else {
            print("requestRecordPermission unrecognized")
        }
    }
    
    func meterUpdate(){
        self.recorder.updateMeters()
        let avg = self.recorder.averagePowerForChannel(0)
        if(avg > self.meterHigh){
            self.meterHigh = avg
        }
        if(avg < self.meterLow){
            self.meterLow = avg
        }
        self.onRecordingMeterUpdate.fire((avg, self.meterLow,self.meterHigh))
    }

    func setSessionPlayback() {
        print("sessionPlayback")
        let session:AVAudioSession = AVAudioSession.sharedInstance()
        do{
            try session.overrideOutputAudioPort(AVAudioSessionPortOverride.Speaker)
            try session.setActive(true)
        }catch{
            print("could not setSessionPlayback")
        }
        
    }
    
    func setSessionPlayAndRecord() {
        print("session PlayAndRecord")
        let session:AVAudioSession = AVAudioSession.sharedInstance()
        do{
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try session.setActive(true)
        }catch{
            print("could not setSessionPlayAndRecord")
        }
    }
    
    // MARK: Utilities
    
    func cleanFiles(){
        print("Cleanup Phrases Folder")
        let fileManager = NSFileManager.defaultManager()
        
        if let docsDir = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first,
            let phrasesDir = NSURL(string:"\(docsDir.path)/phrases"){
            do{
                let contents = try fileManager.contentsOfDirectoryAtURL(phrasesDir, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.SkipsHiddenFiles)
                
                    for file:NSURL in contents{
                        if(file.path!.hasSuffix("wav")){
                            print("Removing \(file.path!)")
                            do{
                                try fileManager.removeItemAtURL(file)
                            }catch{}
                        }
                    }
                
            }catch{
                
            }
                
                
        }
    }
    
    // MARK: Audio Queue Recording (Stub, non functional)
    
    /*
    let audioEngine = AVAudioEngine()
    var len:Int = 0
    
    func aqSetup(){
        let inputNode = audioEngine.inputNode
        let bus = 0

        inputNode!.installTapOnBus(bus, bufferSize: 2048, format: inputNode!.inputFormatForBus(bus), block: {
            (buffer:AVAudioPCMBuffer!, time:AVAudioTime!) -> Void in
            //let channelCount = inputNode!.inputFormatForBus(bus).channelCount  // given PCMBuffer channel count is 1
            let last = self.len
            self.len = Int(buffer.frameCapacity * buffer.format.streamDescription.memory.mBytesPerFrame)
            let readLen = self.len - last
                        //var channels = UnsafeBufferPointer(start: buffer.floatChannelData, count: channelCount)
            let data = NSData(bytes: buffer.floatChannelData[0], length: readLen)
            print("buffer dataLen:\(data.length)  len:\(self.len)  last:\(last)")

            self.onRecordingData.fire(data)
        })
        

        audioEngine.prepare()
    }
    
    func aqStartRecording(){
        

        audioEngine.startAndReturnError(nil)

        
    }
    
    func aqEndRecording(){
        audioEngine.stop()
    }
*/
}


struct RecordingStatus{
    var dataFormatL:AudioStreamBasicDescription
    var queue:AudioQueueRef
    var buffers:AudioQueueBufferRef
    var audioFile:AudioFileID
    var currentPacket:Int64
    var recording:Bool
}

//NSNotificationCenter.defaultCenter().addObserver(self,
//    selector:"routeChange:",
//    name:AVAudioSessionRouteChangeNotification,
//    object:nil)


// MARK: AVAudioRecorderDelegate
extension AudioControl : AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool){
        print("finished recording \(flag)")
        AudioControl.shared.delegate?.recorderDidFinishRecording(flag)
        NSNotificationCenter.defaultCenter().postNotificationName("recordStop", object: nil)
    }
    
    func audioRecorderEncodeErrorDidOccur(recorder: AVAudioRecorder, error: NSError?){
        print(error)
    }
}

// MARK: AVAudioPlayerDelegate
extension AudioControl : AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        delegate?.playerDidFinishPlaying(flag)
        NSNotificationCenter.defaultCenter().postNotificationName("playStop", object: nil)
    }
    
    func audioPlayerDecodeErrorDidOccur(player: AVAudioPlayer, error: NSError?) {
        print("\(error?.localizedDescription)")
    }
}