//
//  Channel.swift
//  TFSChatTransport
//
//  Created by p.baranov on 06.03.2023.
//

import Foundation

public struct Channel: Codable {
    let id: String
    let name: String
    let logoURL: String?
    let lastMessage: String?
    let lastActivity: Date?
}
