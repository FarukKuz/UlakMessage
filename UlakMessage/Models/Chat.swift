//
//  Chat.swift
//  UlakMessage
//
//  Konum: Models/Chat.swift
//

import Foundation

struct Chat: Identifiable, Codable, Equatable {
    var id: String
    var participants: [String] // User ID'leri
    var participantUsernames: [String: String] // [userId: username]
    var participantDisplayNames: [String: String] // [userId: displayName]
    var lastMessage: String?
    var lastMessageTimestamp: Date?
    var lastMessageSenderId: String?
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case participants
        case participantUsernames
        case participantDisplayNames
        case lastMessage
        case lastMessageTimestamp
        case lastMessageSenderId
        case createdAt
    }
    
    init(id: String = UUID().uuidString, participants: [String], participantUsernames: [String: String], participantDisplayNames: [String: String], lastMessage: String? = nil, lastMessageTimestamp: Date? = nil, lastMessageSenderId: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.participants = participants
        self.participantUsernames = participantUsernames
        self.participantDisplayNames = participantDisplayNames
        self.lastMessage = lastMessage
        self.lastMessageTimestamp = lastMessageTimestamp
        self.lastMessageSenderId = lastMessageSenderId
        self.createdAt = createdAt
    }
    
    // Karşı tarafın bilgilerini al
    func getOtherParticipant(currentUserId: String) -> (id: String, username: String, displayName: String?)? {
        guard let otherUserId = participants.first(where: { $0 != currentUserId }),
              let username = participantUsernames[otherUserId] else {
            return nil
        }
        let displayName = participantDisplayNames[otherUserId]
        return (otherUserId, username, displayName)
    }
    
    static func == (lhs: Chat, rhs: Chat) -> Bool {
        return lhs.id == rhs.id
    }
}
