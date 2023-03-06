//
//  Message.swift
//  TFSChatTransport
//
//  Created by p.baranov on 07.03.2023.
//

import Foundation

public struct Message: Codable {
    let text: String
    let userID: String
    let date: Date
}
