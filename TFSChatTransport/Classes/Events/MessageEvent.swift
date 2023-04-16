//
//  MessageEvent.swift
//  TFSChatTransport
//
//  Created by Aleksandr Lis on 17.04.2023.
//

import Foundation

public struct MessageEvent: Decodable {
    let text: String
    let userID: String
    let date: String
}
