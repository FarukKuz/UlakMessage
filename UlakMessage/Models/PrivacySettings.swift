//
//  PrivacySettings.swift
//  UlakMessage
//
//  Konum: Models/PrivacySettings.swift
//

import Foundation

struct PrivacySettings: Codable, Equatable {
    var whoCanMessage: MessagePrivacy
    
    enum MessagePrivacy: String, Codable, CaseIterable {
        case everyone = "Herkes"
        case friendsOnly = "Sadece Arkadaşlar"
    }
    
    init(whoCanMessage: MessagePrivacy = .friendsOnly) {
        self.whoCanMessage = whoCanMessage
    }
}
