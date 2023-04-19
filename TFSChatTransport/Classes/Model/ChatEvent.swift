//
//  ChatEvent.swift
//  TFSChatTransport
//
//  Created by Aleksandr Lis on 17.04.2023.
//

import Foundation

public struct ChatEvent: Decodable {
    public let eventType: EventType
    public let resourceID: String
    
    public enum EventType: String, Decodable {
        case add
        case update
        case delete
    }
}
