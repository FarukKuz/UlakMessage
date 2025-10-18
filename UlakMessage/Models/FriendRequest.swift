//
//  FriendRequest.swift
//  UlakMessage
//
//  Konum: Models/FriendRequest.swift
//

import Foundation

struct FriendRequest: Identifiable, Codable, Equatable {
    var id: String
    var fromUserId: String
    var fromUsername: String
    var fromDisplayName: String?
    var fromPhotoURL: String?
    var toUserId: String
    var status: RequestStatus
    var createdAt: Date
    
    enum RequestStatus: String, Codable {
        case pending = "pending"
        case accepted = "accepted"
        case rejected = "rejected"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case fromUserId
        case fromUsername
        case fromDisplayName
        case fromPhotoURL
        case toUserId
        case status
        case createdAt
    }
}
