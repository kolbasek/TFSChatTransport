//
//  Message.swift
//  TFSChatTransport
//
//  Created by p.baranov on 07.03.2023.
//

import Foundation

public struct Message: Codable {
    public let id: String
    public let text: String
    public let userID: String
    public let userName: String
    public let date: Date
}
