//
//  NetworkHandler.swift
//  OnTheMyMap
//
//  Created by Kundan Kale on 06/09/19.
//  Copyright © 2019 Kundan Kale. All rights reserved.
//

import UIKit

class NetworkHandler: NSObject {

    typealias ErrorBlock = ((Errors?) -> Void)
    
    func handleError(error: Error!, onComplete: @escaping ErrorBlock) {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                onComplete(Errors.NetworkError)
                break
            default:
                onComplete(Errors.ServerError)
            }
        }
        onComplete(Errors.ServerError)
    }
}
