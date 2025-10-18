//
//  Message.swift
//  UlakMessage
//
//  Konum: Models/Message.swift
//

import Foundation

enum MessageType: String, Codable {
    case text = "text"
    case image = "image"
    case video = "video"
    case audio = "audio"
}

struct Message: Identifiable, Codable, Equatable {
    var id: String
    var chatId: String
    var senderId: String
    var senderUsername: String
    var text: String
    var timestamp: Date
    var isRead: Bool
    
    // Medya desteği için yeni alanlar
    var type: MessageType
    var mediaURL: String?
    var thumbnailURL: String?
    var mediaDuration: TimeInterval? // Video/Audio için
    
    enum CodingKeys: String, CodingKey {
        case id
        case chatId
        case senderId
        case senderUsername
        case text
        case timestamp
        case isRead
        case type
        case mediaURL
        case thumbnailURL
        case mediaDuration
    }
    
    init(id: String = UUID().uuidString,
         chatId: String,
         senderId: String,
         senderUsername: String,
         text: String,
         timestamp: Date = Date(),
         isRead: Bool = false,
         type: MessageType = .text,
         mediaURL: String? = nil,
         thumbnailURL: String? = nil,
         mediaDuration: TimeInterval? = nil) {
        self.id = id
        self.chatId = chatId
        self.senderId = senderId
        self.senderUsername = senderUsername
        self.text = text
        self.timestamp = timestamp
        self.isRead = isRead
        self.type = type
        self.mediaURL = mediaURL
        self.thumbnailURL = thumbnailURL
        self.mediaDuration = mediaDuration
    }
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
}
