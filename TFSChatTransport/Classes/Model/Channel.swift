//
//  Channel.swift
//  TFSChatTransport
//
//  Created by p.baranov on 06.03.2023.
//

import Foundation

public struct Channel: Codable {
    public let id: String
    public let name: String
    public let logoURL: String?
    public let lastMessage: String?
    public let lastActivity: Date?
}
