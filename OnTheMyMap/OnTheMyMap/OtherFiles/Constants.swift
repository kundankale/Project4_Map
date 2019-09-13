//
//  Constants.swift
//  OnTheMyMap
//
//  Created by Kundan Kale on 08/09/19.
//  Copyright © 2019 Kundan Kale. All rights reserved.
//

import Foundation
import MapKit

struct Constants {
    
    static let PARSE_ENPOINT_URL = "https://parse.udacity.com/parse/classes"
    static let PARSE_APP_ID = "GewLdsL7o5Eb8iug6EQrX47CA9cyum8ye0dnAbIrSSS"
    static let REST_API_KEY = "DseUSEpUKo7aBYM737QuWThTdiRmTux3YayKd4gYSSS"
    
    struct Method {
        static let GET: String = "GET"
        static let POST: String = "POST"
        static let DELETE: String = "DELETE"
    }
    
    struct HeaderKey {
        static let CONTENT_TYPE = "Content-Type"
        static let ACCEPT = "Accept"
    }
    
    struct HeaderValue {
        static let MIME_TYPE_JSON = "application/json"
    }
    
    struct UdacityAuth {
        static let KEY_UDACITY = "udacity"
        static let KEY_USERNAME = "username"
        static let KEY_PASSWORD = "password"
        
        static let KEY_STATUS = "status"
        static let KEY_ACCOUNT = "account"
        static let KEY_ACC_KEY = "key"
        static let KEY_SESSION = "session"
        static let KEY_ID = "id"
        static let KEY_EXPIRATION = "expiration"
    }
}

extension Dictionary {
    func json() -> String {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
            return String(bytes: jsonData, encoding: String.Encoding.utf8) ?? ""
        } catch {
            return ""
        }
    }
}

@available(iOS 10.0, *)
extension StudentLocation {
    
    func annotation() -> MKPointAnnotation {
        let annotation = MKPointAnnotation()
        annotation.coordinate.latitude = self.latitude
        annotation.coordinate.longitude = longitude
        annotation.title = "\(self.firstName) \(self.lastName)"
        annotation.subtitle = self.mediaURL
        return annotation
    }
}

class UserInfo {
    
    var firstName: String
    var lastName: String
    var nickName: String
    var imageUrl: String
    
    init(_ dictionary: NSDictionary) {
        
        let user: NSDictionary = dictionary
        
        self.firstName = user["first_name"] as? String ?? ""
        self.lastName = user["last_name"] as? String ?? ""
        self.nickName = user["nickname"] as? String ?? ""
        self.imageUrl = user["_image_url"] as? String ?? ""
    }
    
    func isValid() -> Bool {
        return !self.firstName.isEmpty && !self.lastName.isEmpty
    }
}

@available(iOS 10.0, *)
@available(iOS 10.0, *)
class Cache {
    
    static let shared = Cache()
    
    var userInfo: UserInfo?
    var studentLocations: [StudentLocation]
    
    private init() {
        studentLocations = [StudentLocation]()
    }
    
    func clear() {
        userInfo = nil
        studentLocations.removeAll()
    }
}
