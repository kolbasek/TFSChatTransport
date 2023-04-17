//
//  SSEEvent.swift
//  TFSChatTransport
//
//  Created by Aleksandr Lis on 17.04.2023.
//

import Foundation

public struct SSEEvent: Decodable {
    let eventType: EventType
    let resourceID: String
}

public enum EventType: String, Decodable {
    case add
    case update
    case delete
}
