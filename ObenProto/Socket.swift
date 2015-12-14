//
//  Socket.swift
//  ObenProto
//
//  Created by Will on 5/27/15.
//  Copyright (c) 2015 FFORM. All rights reserved.
//

import UIKit
import CFNetwork
import SwiftyJSON
import Signals

class Socket: NSObject {

    private var inputStream: NSInputStream!
    private var outputStream: NSOutputStream!
    private var writeBuffer =  NSMutableData()
    private var writeIsAvailable = false
    
    let onSocketData = Signal<SwiftyJSON.JSON>()
    let onSocketWriteBufferEmpty = Signal<Void>()
    let onSocketWriting = Signal<String>()
    let onSocketError = Signal<NSError>()
    
    convenience init(url:NSURL!) {
        self.init()
        
        
        var readStream:  Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        let host:CFString = url.host!
        let port = url.port!.unsignedIntValue

        print("socket::init \(host) : \(port)")
        CFStreamCreatePairWithSocketToHost(nil, host, port, &readStream, &writeStream)
        
        self.inputStream = readStream!.takeRetainedValue()
        self.outputStream = writeStream!.takeRetainedValue()
        
        self.inputStream.delegate = self
        self.outputStream.delegate = self
        
        self.inputStream.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        self.outputStream.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        
        self.inputStream.open()
        self.outputStream.open()
     
    }
    
    func close(){
        self.inputStream.close()
        self.outputStream.close()
        self.inputStream.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        self.outputStream.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
    }
    
    func writeBytes(data:NSData!){
        //let bin = 0x0
        //var comp = NSMutableData(data:data);
        //comp.appendBytes([0x0], length: 1)
        self.writeBuffer.appendData(data)
        self._writeIfAvailable()
    }
    
    func _writeIfAvailable(){
        if(self.writeIsAvailable == true && self.writeBuffer.length > 0){
            
            let top = min(1024, self.writeBuffer.length)
            var outBuffer = [UInt8](count:top, repeatedValue:0)
            let range = NSRange(0...top-1)
            
            //print("write buffer top:\(top)/\(self.writeBuffer.length):total")
            
            self.writeBuffer.getBytes(&outBuffer, length: top)
            self.writeBuffer.replaceBytesInRange(range, withBytes: nil, length: 0)
            self.outputStream.write(outBuffer, maxLength: outBuffer.count)
            
            self.onSocketWriting.fire("top:\(top)/\(self.writeBuffer.length):total")
            
            self.writeIsAvailable = false
        }else{
            self.onSocketWriteBufferEmpty.fire()
        }
    }
    
}

extension Socket: NSStreamDelegate{
    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent){

        switch (eventCode){
            case NSStreamEvent.ErrorOccurred:
                //NSLog("ErrorOccurred")
                print(aStream.streamError)
                self.onSocketError.fire(aStream.streamError!)
                break
            case NSStreamEvent.EndEncountered:
                //NSLog("EndEncountered")
                break
            case NSStreamEvent.None:
                //NSLog("None")
                break
            case NSStreamEvent.HasBytesAvailable:
                //NSLog("HasBytesAvaible")
                var buffer = [UInt8](count: 1024, repeatedValue: 0)
                if ( aStream == self.inputStream){
                    
                    while (self.inputStream.hasBytesAvailable){
                        let len = self.inputStream.read(&buffer, maxLength: buffer.count)
                        if(len > 0){
                            
                        }
                    }
                    

                    var output = NSString(bytes: &buffer, length: buffer.count, encoding: NSUTF8StringEncoding)
                    output = output!.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "\r\n\t\0"))
                    let outData = output!.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion:false)!
                    var err: NSError?
                    let res = SwiftyJSON.JSON(data:outData,options: NSJSONReadingOptions.AllowFragments, error: &err)
                    if(err == nil){
                        self.onSocketData.fire(res)
                    }
                }
                break
            case NSStreamEvent():
                //NSLog("allZeros")
                break
            case NSStreamEvent.OpenCompleted:
                //NSLog("OpenCompleted")
                break
            case NSStreamEvent.HasSpaceAvailable:
                //NSLog("HasSpaceAvailable")
                if ( aStream == self.outputStream){
                    writeIsAvailable = true
                    self._writeIfAvailable()
                }
                break
            
        default:
            NSLog("Unknown Stream Event")
            break
        }
    }
}
