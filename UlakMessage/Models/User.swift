//
//  User.swift
//  UlakMessage
//
//  Konum: Models/User.swift
//

import Foundation

struct User: Identifiable, Codable, Equatable {
    var id: String
    var email: String
    var username: String // Eşsiz kullanıcı adı
    var displayName: String?
    var photoURL: String?
    var createdAt: Date
    var lastSeen: Date?
    var isOnline: Bool
    var privacySettings: PrivacySettings
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case username
        case displayName
        case photoURL
        case createdAt
        case lastSeen
        case isOnline
        case privacySettings
    }
    
    init(id: String, email: String, username: String, displayName: String? = nil, photoURL: String? = nil, createdAt: Date = Date(), lastSeen: Date? = nil, isOnline: Bool = false, privacySettings: PrivacySettings = PrivacySettings()) {
        self.id = id
        self.email = email
        self.username = username
        self.displayName = displayName
        self.photoURL = photoURL
        self.createdAt = createdAt
        self.lastSeen = lastSeen
        self.isOnline = isOnline
        self.privacySettings = privacySettings
    }
    
    // Equatable protokolü için özel karşılaştırma
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id &&
               lhs.email == rhs.email &&
               lhs.username == rhs.username &&
               lhs.displayName == rhs.displayName &&
               lhs.photoURL == rhs.photoURL &&
               lhs.isOnline == rhs.isOnline
    }
}
