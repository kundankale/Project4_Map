//
//  Authentication.swift
//  OnTheMyMap
//
//  Created by Kundan Kale on 06/09/19.
//  Copyright © 2019 Kundan Kale. All rights reserved.
//

import Foundation

class Authentication: NetworkHandler {
    
    
    private let AUTH_ENDPOINT_URL: URL = URL(string: "https://onthemap-api.udacity.com/v1/session")!
    private let USER_ENDPOINT_URL: URL = URL(string: "https://onthemap-api.udacity.com/v1/users")!
    
    static let shared = Authentication()
    
    private override init() {}
    
    func tryAutoLogin(_ onComplete: @escaping (Errors?) -> Void) {
        // First get UserAuthRepsonse from UserDefaults
        // If no existing session, or if expired, return with credential expired error
        let authReponse = UserAuthStorage.shared.getStoredUserAuth() // Get from User Defaults
        if authReponse == nil || (authReponse?.isExpired())! {
            onComplete(Errors.CredentialExpiredError)
            return
        }
        
        // We have session key now, get UserInfo
        getUserData(authResponse: authReponse!, onComplete: onComplete)
    }
    
    func makeLoginCall(email: String, password: String,
                       onComplete: @escaping (Errors?) -> Void) {
        var request = URLRequest(url: AUTH_ENDPOINT_URL)
        
        request.httpMethod = Constants.Method.POST
        request.addValue(Constants.HeaderValue.MIME_TYPE_JSON, forHTTPHeaderField: Constants.HeaderKey.CONTENT_TYPE)
        request.addValue(Constants.HeaderValue.MIME_TYPE_JSON, forHTTPHeaderField: Constants.HeaderKey.ACCEPT)
        
        let credentials = [Constants.UdacityAuth.KEY_UDACITY : [ Constants.UdacityAuth.KEY_USERNAME : email, Constants.UdacityAuth.KEY_PASSWORD: password]]
        let authData = credentials.json()
        request.httpBody = authData.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle network error here
            if error != nil {
                self.handleError(error: error, onComplete: onComplete)
                return
            }
            
            let range = (5..<data!.count)
            let newData = data?.subdata(in: range)
            let responseDict = try! JSONSerialization.jsonObject(with: newData!, options: .allowFragments) as! NSDictionary
            
            if responseDict[Constants.UdacityAuth.KEY_ACCOUNT] != nil && responseDict[Constants.UdacityAuth.KEY_SESSION] != nil {
                // Store user auth in storage and the call get user data
                let authResponse = AuthenticationResponse(responseDict)
                UserAuthStorage.shared.storeUserAuth(authResponse)
                
                self.getUserData(authResponse: authResponse, onComplete: onComplete)
                return
            } else if responseDict[Constants.UdacityAuth.KEY_STATUS] != nil {
                let status = responseDict[Constants.UdacityAuth.KEY_STATUS] as! Int
                // 400 : Parameter Missing
                // 403 : Account not found or invalid credentials.
                if status == 403 {
                    onComplete(Errors.WrongCredentialError)
                    return
                }
            } else {
                // If all possible+valid cases are over
                onComplete(Errors.UnknownError)
            }
        }
        task.resume()
    }
    
    private func getUserData(authResponse: AuthenticationResponse, onComplete: @escaping (Errors?) -> Void) {
        
        var currentUserEndpointUrl: URL = USER_ENDPOINT_URL
        currentUserEndpointUrl.appendPathComponent(authResponse.accountKey)
        
        let request = URLRequest(url: currentUserEndpointUrl)
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if error != nil {
                self.handleError(error: error, onComplete: onComplete)
                return
            }
            let range = (5..<data!.count)
            let newData = data?.subdata(in: range)
            let responseDict = try! JSONSerialization.jsonObject(with: newData!, options: .allowFragments) as! NSDictionary
            
            let userInfo = UserInfo(responseDict)
            
            if userInfo.isValid() {
                if #available(iOS 10.0, *) {
                    Cache.shared.userInfo = userInfo
                } else {
                    // Fallback on earlier versions
                }
                onComplete(nil)
            } else {
                onComplete(Errors.ServerError)
            }
        }
        
        task.resume()
    }
    
    // Delete Udacity session
    func makeLogoutCall(_ onComplete: @escaping (Errors?) -> Void) {
        var request = URLRequest(url: AUTH_ENDPOINT_URL)
        request.httpMethod = Constants.Method.DELETE
        var xsrfCookie: HTTPCookie? = nil
        let sharedCookieStorage = HTTPCookieStorage.shared
        for cookie in sharedCookieStorage.cookies! {
            if cookie.name == "XSRF-TOKEN" { xsrfCookie = cookie }
        }
        if let xsrfCookie = xsrfCookie {
            request.setValue(xsrfCookie.value, forHTTPHeaderField: "X-XSRF-TOKEN")
        }
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if error != nil {
                self.handleError(error: error, onComplete: onComplete)
                return
            }
            // Since logout on server is success, also clear local data
            if #available(iOS 10.0, *) {
                Cache.shared.clear()
            } else {
                // Fallback on earlier versions
            }
            UserAuthStorage.shared.clearUserAuth()
            
            onComplete(nil)
        }
        task.resume()
    }
}

// ******* Parsing URL Helper ******
@available(iOS 10.0, *)
class ParseHandler: NetworkHandler {
    
    private let PARSE_ENDPOINT_URL = URL(string:"https://onthemap-api.udacity.com/v1/StudentLocation")!
    private let PARSE_APP_ID_HEADER = "X-Parse-Application-Id"
    private let PARSE_API_KEY_HEADER = "X-Parse-REST-API-Key"
    
    private let PARSE_APP_ID = "GewLdsL7o5Eb8iug6EQrX47CA9cyum8ye0dnAbIrSSS"
    private let PARSE_API_KEY = "DseUSEpUKo7aBYM737QuWThTdiRmTux3YayKd4gYSSS"
    
    static let shared = ParseHandler()
    
    var isLoadingStudentLocations: Bool
    
    var callbackArray = [ErrorBlock]()
    
    private override init() {
        isLoadingStudentLocations = false
        callbackArray = [ErrorBlock]()
    }
    
    func loadStudentLocations(limit: Int, skip: Int, onComplete: @escaping ErrorBlock) {
        // Add callback to the array
        callbackArray.append(onComplete)
        
        // If there is exisiting network call going on, return immediately
        if (isLoadingStudentLocations) {
            return
        }
        
        isLoadingStudentLocations = true
        
        let params = "limit=\(limit)&skip=\(skip)&order=-updatedAt"
        
        let requestUrl = URL(string: "\(PARSE_ENDPOINT_URL.absoluteString)?\(params)")
        var request = URLRequest(url: requestUrl!)
        
        request.addValue(PARSE_APP_ID, forHTTPHeaderField: PARSE_APP_ID_HEADER)
        request.addValue(PARSE_API_KEY, forHTTPHeaderField: PARSE_API_KEY_HEADER)
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if error != nil {
                // Handle error
                self.handleCallbacks(error!)
            }
            
            let responseDict = try! JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! NSDictionary
            let resultDict: [NSDictionary] = responseDict["results"] as! [NSDictionary]
            
            var studentLocations = [StudentLocation]()
            for dictionary in resultDict {
                if let studLocation = StudentLocation(dictionary) {
                    studentLocations.append(studLocation)
                }
            }
            
            Cache.shared.studentLocations = studentLocations
            self.handleCallbacks()
        }
        
        task.resume()
    }
    
    private func handleCallbacks(_ error: Error? = nil) {
        if error != nil {
            for callback in self.callbackArray {
                self.handleError(error: error, onComplete: callback)
            }
        } else {
            for callback in self.callbackArray {
                callback(nil)
            }
        }
        self.callbackArray.removeAll()
        isLoadingStudentLocations = false
    }
    
    func postStudentLocation(locationString: String, mediaUrl: String, lat: Double, lng: Double, onComplete: @escaping ErrorBlock) {
        var request = URLRequest(url: PARSE_ENDPOINT_URL)
        request.httpMethod = Constants.Method.POST
        request.addValue(PARSE_APP_ID, forHTTPHeaderField: PARSE_APP_ID_HEADER)
        request.addValue(PARSE_API_KEY, forHTTPHeaderField: PARSE_API_KEY_HEADER)
        request.addValue(Constants.HeaderValue.MIME_TYPE_JSON, forHTTPHeaderField: Constants.HeaderKey.CONTENT_TYPE)
        let dataDictionary = [
            "uniqueKey": UserAuthStorage.shared.getStoredUserAuth()?.accountKey as Any,
            "firstName": Cache.shared.userInfo?.firstName as Any,
            "lastName": Cache.shared.userInfo?.lastName as Any,
            "mapString": locationString,
            "mediaURL": mediaUrl,
            "latitude": lat,
            "longitude": lng
            ] as [String : Any]
        let dataString = dataDictionary.json()
        request.httpBody = dataString.data(using: .utf8)
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if error != nil {
                self.handleError(error: error, onComplete: onComplete)
                return
            }
            onComplete(nil)
        }
        task.resume()
    }
}
class UserAuthStorage {
    
    static let shared: UserAuthStorage = UserAuthStorage()
    
    private init() {}
    
    func getStoredUserAuth() -> AuthenticationResponse? {
        // Return from UserDefaults
        let sessionId = UserDefaults.standard.string(forKey: "AuthenticationResponse.sessionId")
        let accountKey = UserDefaults.standard.string(forKey: "AuthenticationResponse.accountKey")
        let expirationString = UserDefaults.standard.string(forKey: "AuthenticationResponse.dateString")
        if (sessionId != nil && accountKey != nil && expirationString != nil) {
            return AuthenticationResponse(sessionId: sessionId!, expirationString: expirationString!, accountKey: accountKey!)
        }
        return nil
    }
    
    func storeUserAuth(_ auth: AuthenticationResponse) {
        // Store in UserDefaults
        UserDefaults.standard.set(auth.sessionId, forKey: "AuthenticationResponse.sessionId")
        UserDefaults.standard.set(auth.accountKey, forKey: "AuthenticationResponse.accountKey")
        UserDefaults.standard.set(auth.dateString(), forKey: "AuthenticationResponse.dateString")
    }
    
    func clearUserAuth() {
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "AuthenticationResponse.sessionId")
        UserDefaults.standard.removeObject(forKey: "AuthenticationResponse.accountKey")
        UserDefaults.standard.removeObject(forKey: "AuthenticationResponse.dateString")
    }
}

// ******** Authentication Response class *********
class AuthenticationResponse {
    
    var sessionId: String
    var expiration: Date
    var accountKey: String
    
    init(sessionId: String, expirationString: String, accountKey: String) {
        self.sessionId = sessionId
        self.accountKey = accountKey
        
        // Create DateFormatter to format String
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        dateFormatter.timeZone = TimeZone.current
        
        // Set default session expiray to one hour after current time
        let defaultExpiration = Calendar.current.date(byAdding: .hour, value: 1, to: Date())
        
        // Parse session expiration date
        self.expiration =  dateFormatter.date(from: expirationString) ?? defaultExpiration!
    }
    
    init(_ dictionary: NSDictionary) {
        let account: NSDictionary = dictionary[Constants.UdacityAuth.KEY_ACCOUNT] as! NSDictionary
        self.accountKey = account[Constants.UdacityAuth.KEY_ACC_KEY] as! String
        
        let session: NSDictionary = dictionary[Constants.UdacityAuth.KEY_SESSION] as! NSDictionary
        self.sessionId = session[Constants.UdacityAuth.KEY_ID] as! String
        
        let expirationString: String = session[Constants.UdacityAuth.KEY_EXPIRATION] as! String
        
        // Create DateFormatter to format String
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        dateFormatter.timeZone = TimeZone.current
        
        // Set default session expiray to one hour after current time
        let defaultExpiration = Calendar.current.date(byAdding: .hour, value: 1, to: Date())
        
        // Parse session expiration date
        self.expiration =  dateFormatter.date(from: expirationString) ?? defaultExpiration!
    }
    
    func dateString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        dateFormatter.timeZone = TimeZone.current
        
        return dateFormatter.string(from: self.expiration)
    }
    
    func isExpired() -> Bool {
        return Date() > self.expiration
    }
}

