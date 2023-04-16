//
//  TFSError.swift
//  TFSChatTransport
//
//  Created by Aleksandr Lis on 06.03.2023.
//

import Foundation

enum TFSError: Error, CustomStringConvertible {
    case makeRequest
    case other
    
    var description: String {
        switch self {
        case .makeRequest:
            return "Failed to make request"
        case .other:
            return "Something went wrong"
        }
    }
}
