//
//  ObenAPI.swift
//  ObenProto
//
//  Created by Will on 2/26/15.
//  Copyright (c) 2015 FFORM. All rights reserved.
//

import Foundation
import UIKit
import SwiftHTTP

import SwiftyJSON
import Signals


struct ObenUpload {
    var name:String
    var filename:String
    var data:NSData
}

struct Avatar{
    var id: String
    var name: String
    var canDelete: Bool
    var image: String
    var rating:Int
}

struct Phrase{
    var recordID:String
    var phrase:String
    var example:String
    var recordingURL:String = ""
    init(id:String, phrase:String, exampleURL:String){
        self.recordID = id
        self.phrase = phrase
        self.example = exampleURL
    }
}

struct MorphResult{
    var avatarId:String
    var morphId:String
    var transcription:String
    var url:String
    var type:String
    var mode:Int
    var originalUrl:String
}

class ObenAPI {
    
    var userID = ""
    var avatarID = ""
    var cookie = NSHTTPCookie()
    
    // Holds a HTTP Basic Auth string from login onwards
    var basicAuthEncoded = ""
    
    var baseURL:String{
        get{
            return Preferences.shared.environment == "development" ? "https://oben.us/morphing" : "https://www.oben.us/morphing"
        }
    }
    var streamIP:String{
        get{
            return Preferences.shared.environment == "development" ? "oben.us:7777" : "www.oben.us:7777"
        }
    }
    
    class var shared: ObenAPI {
        struct Static {
            static let instance: ObenAPI = ObenAPI()
        }
        return Static.instance
    }
    
    
    func isLoggedIn() -> Bool{
        return (userID != "")
    }
    
    func hasAvatar() -> Bool{
        return (avatarID != "")
    }
    
    //MARK: - Auth
    
    func login( complete: ((success:Bool)->Void)! ){
        let request = HTTPTask()
        request.baseURL = baseURL
        let params: [String: String] = [
            "userEmail" : Preferences.shared.userEmail, //"ObenSesame@ObenSesame.com",
            "userPassword": Preferences.shared.userPass,//"ObenSesame",
            "userDisplayName": NSUUID().UUIDString
        ]
        request.requestSerializer.HTTPShouldHandleCookies = true
        let authData = "ObenUp:ObenSesame!".dataUsingEncoding(NSASCIIStringEncoding, allowLossyConversion: false)
        let authValue = "Basic \(authData!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding76CharacterLineLength))"
        self.basicAuthEncoded = authValue
        print("Basic auth :   \(self.basicAuthEncoded)")
        request.requestSerializer.headers["Authorization"] = self.basicAuthEncoded
        
        request.POST("ws/MorphingService/loginUser", parameters: params){(response: HTTPResponse) in
            //Fail
            if let error = response.error{
                print("error: \(error)")
                complete(success:false)
            }
            
            if let data = response.responseObject as? NSData {
                let json:SwiftyJSON.JSON = SwiftyJSON.JSON(data: data, options: NSJSONReadingOptions.AllowFragments, error: nil)
                
                if( json["User"]["login"].string == "ERROR"){
                    print("Error logging in")
                    complete(success:false)
                }else{
                    print("Logged In")
                    //print(json)
                    
                    self.userID = json["User"]["userId"].stringValue
                    
                    self.getUserAvatar(complete)
                    
                    // Now get a cookie for user, because, ....
                    //self.getCookie()
                }
                
            }
            
            
        }

    }
    
    func logout(){
        Preferences.shared.userEmail = ""
        Preferences.shared.userPass = ""
        

        Utilities.makeDirectory("phrases", clean: true)
        Utilities.makeDirectory("morphs", clean: true)
        Utilities.makeDirectory("shares", clean: true)
        
        let request = HTTPTask()
        request.baseURL = baseURL
        request.requestSerializer.headers["Authorization"] = self.basicAuthEncoded

        request.POST("ws/MorphingService/logoutUser", parameters: nil, completionHandler: {(response:HTTPResponse) -> Void in
            print("Log out endpoint done")
            if(response.statusCode != 200){
                print("ERROR logging out")
            }
        })
    }
    
    func getCookie(){
        let request = HTTPTask()
        request.baseURL = baseURL
        let params: [String: String] = [
            "email" : Preferences.shared.userEmail,
            "password": Preferences.shared.userPass,
            "displayname":"iOS USER"
        ]
        request.requestSerializer.HTTPShouldHandleCookies = true
        
        request.POST("LoginServlet", parameters: params){(response: HTTPResponse) in
            print(response)
        }

    }
    
    func checkSession( complete: ((Bool)->Void)! ){
        let request = HTTPTask()
        request.baseURL = baseURL
        request.requestSerializer.headers["Authorization"] = self.basicAuthEncoded

        request.GET("ws/MorphingService/getSession", parameters: nil){(response: HTTPResponse) in
            //Fail
            if let error = response.error{
                print("error: \(error)")
                complete(false)
            }
            
            if let data = response.responseObject as? NSData {
                let json:SwiftyJSON.JSON = SwiftyJSON.JSON(data: data, options: NSJSONReadingOptions.AllowFragments, error: nil)
                complete(safeBool(json["Session"]["isValid"].bool))
            }
        }
        
    }
    
    // MARK: - Avatar Stuff
    
    func getUserAvatar( complete: ((success:Bool)->Void)! ){
        let request = HTTPTask()
        let callback = complete
        request.baseURL = baseURL
        request.requestSerializer.HTTPShouldHandleCookies = true
        request.requestSerializer.headers["Authorization"] = self.basicAuthEncoded
        request.GET("ws/MorphingService/getUserAvatar/\(self.userID)", parameters: nil){ (response:HTTPResponse) -> Void in
            
            if let _ = response.error{
                return callback(success: false)
            }
            
            if let data = response.responseObject as? NSData {
                let json:SwiftyJSON.JSON = SwiftyJSON.JSON(data: data, options: NSJSONReadingOptions.AllowFragments, error: nil)
                //print("avatar \(json)")
                //print(json)
                self.avatarID = json["UserAvatar"]["avatarId"].stringValue
                if((callback) != nil){
                    callback(success: true)
                }
                
            }
            
        }
    }
    
    func saveAvatar(complete: ((success:Bool, message:String)->Void)!){
        let request = HTTPTask()
        request.baseURL = baseURL
        request.requestSerializer.HTTPShouldHandleCookies = true
        request.requestSerializer.timeoutInterval = 360
        request.requestSerializer.headers["Authorization"] = self.basicAuthEncoded
        
        let thing = HTTPUpload()
        let date = NSDate()
        //NSCharacterSet *charactersToRemove = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
        //NSString *trimmedReplacement = [[someString componentsSeparatedByCharactersInSet:charactersToRemove] componentsJoinedByString:@""];
        let email = Preferences.shared.userEmail
        let userName = email.componentsSeparatedByString("@").first ?? "Unknown Name"
        let charsToRemove = NSCharacterSet.alphanumericCharacterSet().invertedSet
        
        let avatarName = userName.componentsSeparatedByCharactersInSet(charsToRemove).joinWithSeparator("")
        //avatarName = "\(avatarName)-\(NSUUID().UUIDString)"
        print("Save avatar: \(avatarName)")
        let params: [String: AnyObject] = [
            "avatarName": avatarName,// NSUUID().UUIDString,
            "avatarId": self.avatarID,
            "userId": self.userID,
            "endTime": date.timeIntervalSince1970,
            "bogue":thing
        ]

        request.POST("ws/MorphingService/processUserAvatar", parameters: params){(response: HTTPResponse) in

            if let error = response.error{
                print("error: \(error)")
                return complete(success: false, message:"\(error)")
            }
            
            if(response.statusCode == 200){
                
                complete(success:true, message:"Avatar is processing")
                //self.saveAvatarStatus(complete)
                
            }else{
                print("Error status code")
                complete(success: false, message:"HTTP Status code fail")
            }
            
        }
        
    }
    
    private func saveAvatarStatus(complete:(success:Bool, message:String)->Void){
        print("saveAvatarStatus")
        let delayTime = dispatch_time(DISPATCH_TIME_NOW,
            Int64(5 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            let request = HTTPTask()
            let url = "ws/MorphingService/getStatus/avatar/\(self.avatarID)"
            print("url:\(url)")
            request.baseURL = self.baseURL
            request.requestSerializer.HTTPShouldHandleCookies = true
            request.requestSerializer.headers["Authorization"] = self.basicAuthEncoded
            request.GET(url, parameters: nil){ (response:HTTPResponse) -> Void in
                if let _ = response.error{
                    print("Failed HTTP Request")
                    self.saveAvatarStatus(complete)
                }
                if let data = response.responseObject as? NSData {
                    let json:SwiftyJSON.JSON = SwiftyJSON.JSON(data: data, options: NSJSONReadingOptions.AllowFragments, error: nil)
                    let status = json["Avatar"]["status"].stringValue
                    print("result:\(status)")
                    switch(json["Avatar"]["status"]){
                        case "SUCCESS":
                            complete(success:true, message:"")
                        break
                        case "PENDING":
                            self.saveAvatarStatus(complete)
                        break
                        case "ERROR":
                            complete(success:false, message:json["Avatar"]["message"].stringValue)
                        break
                        default:
                        break
                    }
                }
            }
        }
    }
    
    func deleteAvatar(avatar:Avatar, complete: (()->Void)!){
        let request = HTTPTask()
        request.baseURL = baseURL
        request.requestSerializer.HTTPShouldHandleCookies = true
        request.requestSerializer.headers["Authorization"] = self.basicAuthEncoded
        
        request.DELETE("ws/MorphingService/deleteUserAvatar/\(userID)/\(avatar.id)", parameters: nil){ (response:HTTPResponse) -> Void in
            if let _ = response.error{
                // Unhandled
            }
            if(avatar.id == self.avatarID){
                self.avatarID = ""
            }
            
            if((complete) != nil){
                complete()
            }
        }
        
    }
    
    //MARK: - data
    
    func getPhrases( success:(data:Array<Phrase>)->Void ){
        var dataRows = [Phrase]()
        let request = HTTPTask()
        request.baseURL = baseURL
        request.requestSerializer.HTTPShouldHandleCookies = true
        request.requestSerializer.headers["Authorization"] = self.basicAuthEncoded
        
        request.GET("ws/MorphingService/getPhrases", parameters: nil){ (response:HTTPResponse) -> Void in
            

            if let data = response.responseObject as? NSData {
                let result:SwiftyJSON.JSON = SwiftyJSON.JSON(data: data, options: NSJSONReadingOptions.AllowFragments, error: nil)

                for (_,item) in result {
                    
                    let source = item["Phrase"]
                    let row = Phrase(
                        id: source["recordId"].stringValue,
                        phrase: source["sentence"].stringValue,
                        exampleURL: source["example"].stringValue
                    )

                    dataRows.append(row)
                }
                success(data: dataRows)
            }
        }
            
        
    }

    
    func getAvatars( success:(data:Array<Avatar>)->Void ){
        print("Get avatars: \(self.userID)")
        var avatarList: [Avatar] = []
        let request = HTTPTask()
        request.baseURL = baseURL
        request.requestSerializer.HTTPShouldHandleCookies = true
        request.requestSerializer.headers["Authorization"] = self.basicAuthEncoded
        
        
        request.GET("ws/MorphingService/getAvatars/\(self.userID)", parameters: nil){ (response:HTTPResponse) -> Void in
            
            if let data = response.responseObject as? NSData {
                let json:SwiftyJSON.JSON = SwiftyJSON.JSON(data: data, options: NSJSONReadingOptions.AllowFragments, error: nil)
                for (_,item) in json {
                    
                    let source = item["Avatar"]
                    let avatarName = source["avatarName"].string!
                    let avatar = Avatar(
                        id: safeStr(source["avatarId"].stringValue),
                        name: avatarName.stringByReplacingOccurrencesOfString("_", withString: " ") ,
                        canDelete: safeBool(source["canDelete"].stringValue),
                        image: source["image"].string!,
                        rating: safeInt(source["stageId"].stringValue)
                    )

                    avatarList.append(avatar)
                }
                success(data: avatarList)
            }
        }
        
    }
    
    func getAvatarMorphs( avatarID:String, success:(data:Array<MorphResult>)->Void ){
        
        var morphList: [MorphResult] = []
        let request = HTTPTask()
        request.baseURL = baseURL
        request.requestSerializer.HTTPShouldHandleCookies = true
        request.requestSerializer.headers["Authorization"] = self.basicAuthEncoded
        
        
        request.GET("ws/MorphingService/getAvatarMorphs/\(self.userID)/\(avatarID)", parameters: nil){ (response:HTTPResponse) -> Void in
            
            if let data = response.responseObject as? NSData {
                let json:SwiftyJSON.JSON = SwiftyJSON.JSON(data: data, options: NSJSONReadingOptions.AllowFragments, error: nil)
                for (_,item) in json {
                    let source = item["Morph"]
                    if(!safeStr(source["transcribedText"].stringValue).isEmpty){

                        let morph = MorphResult(
                            avatarId: avatarID,
                            morphId: safeStr(source["morphId"].stringValue),
                            transcription: safeStr(source["transcribedText"].object ),
                            url: safeStr(source["morphURL"].stringValue),
                            type: safeStr(source["transformationType"].object),
                            mode: safeInt(source["mode"].object),
                            originalUrl: safeStr(source["originURL"].stringValue)
                        )
                        
                        morphList.append(morph)
                    }
                    
                }
                morphList.sortInPlace({ (a:MorphResult, b:MorphResult) -> Bool in
                    let num1 = safeInt(a.morphId)
                    let num2 = safeInt(b.morphId)

                    return num1 > num2
                })
                success(data: morphList)
            }
        }
        
    }
    
    func getPreviousAvatarRecordings( avatarID:String, success:(data:[String:AnyObject])->Void ){
        
        let request = HTTPTask()
        request.baseURL = baseURL
        request.requestSerializer.HTTPShouldHandleCookies = true
        request.requestSerializer.headers["Authorization"] = self.basicAuthEncoded
        
        if(avatarID.isEmpty){
            success(data:[String:AnyObject]())
        }else{
            request.GET("ws/MorphingService/getAvatar/\(avatarID)", parameters: nil){ (response:HTTPResponse) -> Void in
                if let _ = response.error{
                    
                }
                if let data = response.responseObject as? NSData {
                    let json:SwiftyJSON.JSON = SwiftyJSON.JSON(data: data, options: NSJSONReadingOptions.AllowFragments, error: nil)
                    let avatar:JSON = json["Avatar"]
                    if let avatarList = avatar.dictionaryObject{
                        success(data: avatarList)
                    }else{
                        success(data: [String:AnyObject]())
                    }
                    
                }
            }
        }
        
        
        
    }
    
    func morphAlignment( targetAvatar:String, complete: (()->Void)! ){
        let request = HTTPTask()
        request.baseURL = baseURL
        request.requestSerializer.HTTPShouldHandleCookies = true
        request.requestSerializer.headers["Authorization"] = self.basicAuthEncoded
        
        request.GET("ws/MorphingService/mapUserAvatar/\(self.avatarID)/\(targetAvatar)", parameters: nil){ (response:HTTPResponse) -> Void in
            if let data = response.responseObject as? NSData {
                let json:SwiftyJSON.JSON = SwiftyJSON.JSON(data: data, options: NSJSONReadingOptions.AllowFragments, error: nil)
                print(json)
                if(complete != nil){
                    complete()
                }
                
            }
        }
        

        
    }
    
    let onMorphStatusPing = Signal<(String,String,Int)>();

    func morphStatus(statusID:String, avatarId:String, complete:((morph:MorphResult?, message:String?, error:String?)->Void)!){
        
        let statusUrl = "ws/MorphingService/getStatus/morphing/\(statusID)"
        let delayTime = dispatch_time(DISPATCH_TIME_NOW,Int64(3 * Double(NSEC_PER_SEC)))
        
        print("MorphStatus \(statusUrl)")
        
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            let request = HTTPTask()
            request.baseURL = self.baseURL
            request.requestSerializer.headers["Authorization"] = self.basicAuthEncoded
            
            print("Get Status URL: \(statusUrl)")
            request.GET(statusUrl, parameters: nil){ (response:HTTPResponse) -> Void in
                
                var responseWasError = false
                
                
                _ = ["tts":"morphURL", "morphing": "morphURL"]
                
                if let data = response.responseObject as? NSData {
                    let json:SwiftyJSON.JSON = SwiftyJSON.JSON(data: data, options: NSJSONReadingOptions.AllowFragments, error: nil)
                    let item = json["Morph"]
                    _ = item["status"].stringValue
                    print(json)
                    dispatch_async(dispatch_get_main_queue(), {
                        self.onMorphStatusPing.fire((item["message"].stringValue, item["status"].stringValue, safeInt( item["progress"].object )))
                    
                    
                        switch(item["status"]){
                        case "SUCCESS":
                            
                            let morph = MorphResult(
                                avatarId: avatarId,
                                morphId: safeStr(item["morphId"].stringValue),
                                transcription: safeStr(item["transcribedText"].object ),
                                url: safeStr(item["morphURL"].stringValue),
                                type: safeStr(item["transformationType"].object),
                                mode: safeInt(item["mode"].object),
                                originalUrl: safeStr(item["originURL"].stringValue)
                            )
                            complete(morph:morph, message:item["transcribedText"].string, error:nil)
                            
                            break
                        case "PENDING":
                            self.morphStatus(statusID, avatarId: avatarId, complete:complete)
                            break
                        case "ERROR":
                            responseWasError = true
                            complete(morph: nil, message:nil, error:item["message"].string)
                            break
                        default:
                            break
                        }
                        
                    })
                }
                
                if(!responseWasError){
                    if let error = response.error{
                        print("Failed HTTP Request")
                        dispatch_async(dispatch_get_main_queue(), {
                            self.onMorphStatusPing.fire((error.localizedDescription, "ERROR" , 0))
                        })
                    }
                }
                
            }
        }//async
    }
    
    func morphDownload( morphURL:String, complete: ((playFile:NSURL)->Void)! ){
        let fileName = "download-file.wav"
        if let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first{
            let newPath = NSURL(fileURLWithPath: "\(path)/\(fileName)")
            morphDownloadTo(morphURL, targetURL: newPath, complete: complete)
        }
        
    }
    func morphDownloadTo( morphURL:String , targetURL:NSURL, complete: ((playFile:NSURL)->Void)!){
        
        let request = HTTPTask()
        request.requestSerializer.headers["Authorization"] = self.basicAuthEncoded
        
        request.download(morphURL, parameters: nil, progress: { (prog:Double) -> Void in
            
            }){ (response:HTTPResponse) -> Void in
                if let error = response.error{
                    print("THERE WAS A DOWNLOAD ERROR \(error)")
                }
                if let url = response.responseObject as? NSURL {
                    
                    let fileManager = NSFileManager.defaultManager()
                    do{
                        try fileManager.removeItemAtURL(targetURL)
                        try fileManager.moveItemAtURL(url, toURL: targetURL)
                        print("Move file from \(url) to \(targetURL.path!)")
                        if(complete != nil){
                            dispatch_async(dispatch_get_main_queue(), {
                                complete(playFile:targetURL)
                            })
                        }
                    }catch{}
                    
                    
                }
                
                
        }
        
    }
    /*
    func betterUpload(){
        var defaultHeaders = Alamofire.Manager.sharedInstance.session.configuration.HTTPAdditionalHeaders ?? [:]

        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let manager = Alamofire.Manager(configuration: configuration)
        var url = NSMutableURLRequest(URL: NSURL(string:"\(baseURL)/VoiceServlet")!)
        url.HTTPMethod = Method.POST.rawValue
        url.HTTPShouldHandleCookies = true

        manager.upload(url, data: AudioControl.shared.dataForSound()).responseJSON { (request, response, JSON, error) in
                            print(JSON)
                    }
    }
    */
    
    func uploadAudioFile(endpoint:String, config:[String:AnyObject], upload:ObenUpload, success:(response:SwiftyJSON.JSON?)->Void){
        print("Start Upload")
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        let url = NSURL(string:"\(baseURL)/\(endpoint)")!
        var request: NSMutableURLRequest?
        let boundary = "----WebKitFormBoundaryjSjD5OZUTlsdyXfd"
        let body = NSMutableData();
        
        
        request = NSMutableURLRequest(URL: url)
        request!.HTTPMethod = "POST"
        request!.timeoutInterval = 60
        request!.HTTPShouldHandleCookies = true
        request!.setValue(self.basicAuthEncoded, forHTTPHeaderField: "Authorization")
        //request!.setValue("\(cookie.name)=\(cookie.value!)", forHTTPHeaderField:"Cookie")
        request!.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField:"Content-Type")
        
        
        
        for(key, val) in config{
            body.appendData("--\(boundary)\r\nContent-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(val)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        }
       
        
        body.appendData("--\(boundary)\r\nContent-Disposition: form-data; name=\"\(upload.name)\"; filename=\"\(upload.filename)\"\r\nContent-Type: audio/wav\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        body.appendData(upload.data)
        body.appendData("\r\n\r\n--\(boundary)--\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
 
        
        request!.setValue("\(body.length)", forHTTPHeaderField: "Content-Length")
        request!.HTTPBody = body
        
        
        NSURLConnection.sendAsynchronousRequest(request!, queue: NSOperationQueue.mainQueue()) { (response:NSURLResponse?, data:NSData?, error:NSError?) -> Void in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            if let httpRes = response as? NSHTTPURLResponse{
                if(httpRes.statusCode == 500){
                    // Simulate proper response for 500s
                    let jsonRes = SwiftyJSON.JSON(data:"{\"UserAvatar\":{\"status\":\"ERROR\"}}".dataUsingEncoding(NSUTF8StringEncoding)!)
                    success(response: jsonRes)
                }else{
                    if let result = data, res = NSString(data: result, encoding: NSUTF8StringEncoding){
                        print(res)
                        
                        let json = JSON(data: result)
                        success(response: json)
                    }
                }
            }
            

        }
    }
    
    
    func textToSpeechWithAvatar( avatarID:String, text:String, lang:String, mode:Int, complete:((morphID:String?, message:String?)->Void) ){
        let request = HTTPTask()
        request.baseURL = baseURL
        request.requestSerializer.headers["Authorization"] = self.basicAuthEncoded
        
        let params: [String: AnyObject] = [
            "userId": self.userID,
            "text": text,
            "avatarId": avatarID,
            "language": lang,
            "mode": mode
        ]
        print(params)
        
        request.POST("ws/MorphingService/textToSpeech", parameters: params){(response: HTTPResponse) in
            
            if let error = response.error{
                print("error: \(error)")
                return complete(morphID:nil, message:error.description)
            }
            
            if let data = response.responseObject as? NSData {
                let json:SwiftyJSON.JSON = SwiftyJSON.JSON(data: data, options: NSJSONReadingOptions.AllowFragments, error: nil)
                print(json)
                if( json["Morph"]["status"].string == "ERROR"){
                    complete(morphID:nil, message:json["Morph"]["message"].string)
                }else{
                    complete(morphID: safeStr(json["Morph"]["morphId"].object),message:json["Morph"]["message"].string)
                }
            }else{
                print("not json")
                complete(morphID: nil,message: nil)
            }
            
        }
        

        
    }
    
    func deleteMorph(morphId:String, completion:(success:Bool)->()){
        
        let request = HTTPTask()
        request.baseURL = baseURL
        request.requestSerializer.HTTPShouldHandleCookies = true
        request.requestSerializer.headers["Authorization"] = self.basicAuthEncoded
        
        request.DELETE("ws/MorphingService/deleteUserMorph/\(self.userID)/\(morphId)", parameters: nil){ (response:HTTPResponse) -> Void in
            
            if let error = response.error{
                print("error: \(error)")
                return completion(success:false)
            }
            
            if let data = response.responseObject as? NSData {
                let json:SwiftyJSON.JSON = SwiftyJSON.JSON(data: data, options: NSJSONReadingOptions.AllowFragments, error: nil)

                return completion(success:( json["Response"]["status"].string == "SUCCESS"))
            }
            
            completion(success:false)
        }

    }
    
    func deleteAllMorphs(avatarId:String, completion:(success:Bool)->()){
        
        let request = HTTPTask()
        request.baseURL = baseURL
        request.requestSerializer.HTTPShouldHandleCookies = true
        request.requestSerializer.headers["Authorization"] = self.basicAuthEncoded
        
        request.DELETE("ws/MorphingService/deleteAllMorphs/\(self.userID)/\(avatarId)", parameters: nil){ (response:HTTPResponse) -> Void in
            
            if let error = response.error{
                print("error: \(error)")
                return completion(success:false)
            }
            
            if let data = response.responseObject as? NSData {
                let json:SwiftyJSON.JSON = SwiftyJSON.JSON(data: data, options: NSJSONReadingOptions.AllowFragments, error: nil)
                
                return completion(success:( json["Response"]["status"].string == "SUCCESS"))
            }
            
            completion(success:false)
        }
        
    }

    func modifyMorph( morph:MorphResult, settings:MorphSettings, mode:Int, success:(String?)->Void ){
        
        
        let request = HTTPTask()
        
        request.baseURL = baseURL
        request.requestSerializer.headers["Authorization"] = self.basicAuthEncoded
        let params: [String: AnyObject] = [
            "userId": self.userID,
            "morphingId": morph.morphId,
            "pitch": settings.pitch,
            "variability": settings.variability,
            "speed": settings.speed,
            "mode": mode,
            "bogus":HTTPUpload()    //Because REST is broken and needs multipart even without a file
        ]

        request.POST("ws/MorphingService/modifyRecording", parameters: params){ (response:HTTPResponse) -> Void in
            if(response.statusCode != 200){
                return success(nil)
            }

            if let data = response.responseObject as? NSData {
                let json:SwiftyJSON.JSON = SwiftyJSON.JSON(data:data)
                if(json["Morph"]["status"].string == "SUCCESS"){
                    return success(json["Morph"]["morphURL"].string)
                }
                
            }
            return success(nil)
        }
        
    }
    
    func modifyMorphSave( morph:MorphResult, done:(Bool)->Void ){
        
        
        let request = HTTPTask()
        
        request.baseURL = baseURL
        request.requestSerializer.headers["Authorization"] = self.basicAuthEncoded
        let params: [String: AnyObject] = [
            "userId": self.userID,
            "morphingId": morph.morphId,
            "bogus":HTTPUpload()    //Because REST is broken and needs multipart even without a file
        ]
        
        request.POST("ws/MorphingService/saveModifiedRecording", parameters: params){ (response:HTTPResponse) -> Void in
            if(response.statusCode != 200){
                return done(false)
            }
            
            if let data = response.responseObject as? NSData {
                let json:SwiftyJSON.JSON = SwiftyJSON.JSON(data:data)
                if(json["Morph"]["status"].string == "SUCCESS"){
                    return done(true)
                }
                
            }
            return done(false)
        }
        
    }
    
    // MARK: Socket
    var rawSocket:Socket?
    

    let onSocketOpen = Signal<Void>()
    let onSocketClose = Signal<Void>()
    let onSocketMsg = Signal<String>()
    
    let onSocketAck = Signal<String>()
    let onSocketReady = Signal<Void>()
    let onSocketError = Signal<String>()
    let onSocketWriteReady = Signal<Void>()
    let onSocketWriting = Signal<String>()
    
    func openSocket(){

        let url = NSURL(string: "ws://\(self.streamIP)")!

        if((self.rawSocket) != nil){
            self.rawSocket?.close()
        }
        self.rawSocket = Socket(url:url)
        
        self.onSocketOpen.fire()
        self.rawSocket?.onSocketData.listen(self, callback: {(res:JSON) -> Void in
            print("Socket data \(res)")
            if(res["action"].stringValue == "STREAM_START"){
                self.onSocketReady.fire()
                NSNotificationCenter.defaultCenter().postNotificationName(SOCKET_READY_NOTIFICATION, object: nil)
            }
            if(res["action"].stringValue == "STREAM_ACK"){
                var mid = res["morphgId"].stringValue
                if(mid.isEmpty){
                    mid = res["morphId"].stringValue
                }
                self.onSocketAck.fire(mid)
            }
        })
        
        self.rawSocket?.onSocketError.listen(self, callback:{(err:NSError) in
            self.onSocketError.fire(err.description)
            NSNotificationCenter.defaultCenter().postNotificationName(SOCKET_ERROR_NOTIFICATION, object: nil)
        })
        self.rawSocket?.onSocketWriteBufferEmpty.listen(self, callback:{
            self.onSocketWriteReady.fire()
        })
        self.rawSocket?.onSocketWriting.listen(self, callback:{(status:String) in
            self.onSocketWriting.fire(status)
        })
    }
    
    func closeSocket(){
        self.rawSocket?.close()
        self.onSocketClose.fire()
    }
    
    func socketWriteData(data:NSData){
        self.rawSocket?.writeBytes(data)
        //let terminator = "\r\n".dataUsingEncoding(NSUTF8StringEncoding)!
        //self.rawSocket?.writeBytes(terminator)
    }
    
    func socketWriteString(str:String){
        
        let data = "\(str)".dataUsingEncoding(NSUTF8StringEncoding)!
        self.rawSocket?.writeBytes(data)
    }

}

