
import UIKit
import Security

class Keychain {
    
    class func save(key: String, data: NSData) -> Bool {
        let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : key,
            kSecValueData as String   : data ]
        
        SecItemDelete(query as CFDictionaryRef)
        
        let status: OSStatus = SecItemAdd(query as CFDictionaryRef, nil)
        
        return status == noErr
    }
    
    class func load(key: String) -> NSData? {
        let query = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key,
            kSecReturnData as String  : kCFBooleanTrue,
            kSecMatchLimit as String  : kSecMatchLimitOne ]
        
        var dataTypeRef :AnyObject?
        
        let status: OSStatus = withUnsafeMutablePointer(&dataTypeRef) { SecItemCopyMatching(query as CFDictionaryRef, UnsafeMutablePointer($0)) }
        
        if status == noErr {
            return dataTypeRef as? NSData
        } else {
            return nil
        }
    }
    
    class func delete(key: String) -> Bool {
        let query = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key ]
        
        let status: OSStatus = SecItemDelete(query as CFDictionaryRef)
        
        return status == noErr
    }
    
    
    class func clear() -> Bool {
        let query = [ kSecClass as String : kSecClassGenericPassword ]
        
        let status: OSStatus = SecItemDelete(query as CFDictionaryRef)
        
        return status == noErr
    }
    
}