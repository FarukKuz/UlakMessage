//
//  Message.swift
//  UlakMessage
//
//  Konum: Models/Message.swift
//

import Foundation

struct Message: Identifiable, Codable, Equatable {
    var id: String
    var chatId: String
    var senderId: String
    var senderUsername: String
    var text: String
    var timestamp: Date
    var isRead: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case chatId
        case senderId
        case senderUsername
        case text
        case timestamp
        case isRead
    }
    
    init(id: String = UUID().uuidString, chatId: String, senderId: String, senderUsername: String, text: String, timestamp: Date = Date(), isRead: Bool = false) {
        self.id = id
        self.chatId = chatId
        self.senderId = senderId
        self.senderUsername = senderUsername
        self.text = text
        self.timestamp = timestamp
        self.isRead = isRead
    }
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
}
