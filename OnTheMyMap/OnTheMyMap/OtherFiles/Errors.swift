//
//  Errors.swift
//  OnTheMyMap
//
//  Created by Kundan Kale on 07/09/19.
//  Copyright © 2019 Kundan Kale. All rights reserved.
//

import Foundation

enum Errors: String {
    case WrongCredentialError = "Invalid credentials provided."
    case CredentialExpiredError = "Please try again for login."
    case NetworkError = "Please check your internet connection and try again."
    case ServerError = "Network error or Auto Login credential is not provided."
    case UnknownError = "Unknow Error."
}
