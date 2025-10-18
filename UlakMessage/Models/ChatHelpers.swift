//
//  ChatHelpers.swift
//  UlakMessage
//
//  Konum: Models/ChatHelpers.swift
//

import Foundation

// Chat ve kullanıcı bilgisi için Identifiable wrapper
struct ChatWithUser: Identifiable {
    let id: String
    let chat: Chat
    let otherUserId: String
    let otherUsername: String
    let otherDisplayName: String?
    
    init(chat: Chat, otherUserId: String, otherUsername: String, otherDisplayName: String?) {
        self.id = chat.id
        self.chat = chat
        self.otherUserId = otherUserId
        self.otherUsername = otherUsername
        self.otherDisplayName = otherDisplayName
    }
    
    init?(chat: Chat, currentUserId: String) {
        guard let otherParticipant = chat.getOtherParticipant(currentUserId: currentUserId) else {
            return nil
        }
        self.id = chat.id
        self.chat = chat
        self.otherUserId = otherParticipant.id
        self.otherUsername = otherParticipant.username
        self.otherDisplayName = otherParticipant.displayName
    }
}
