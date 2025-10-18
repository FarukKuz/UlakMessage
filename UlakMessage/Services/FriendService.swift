//
//  FriendService.swift
//  UlakMessage
//
//  Konum: Services/FriendService.swift
//

import Foundation
import FirebaseDatabase

class FriendService {
    static let shared = FriendService()
    
    private let database = Database.database().reference()
    
    private init() {}
    
    // Arkadaşlık isteği gönder
    func sendFriendRequest(from: User, to: User) async throws {
        let requestId = "\(from.id)_\(to.id)"
        
        print("📤 Arkadaşlık isteği gönderiliyor:")
        print("   - From: \(from.username) (\(from.id))")
        print("   - To: \(to.username) (\(to.id))")
        print("   - Request ID: \(requestId)")
        
        let request = FriendRequest(
            id: requestId,
            fromUserId: from.id,
            fromUsername: from.username,
            fromDisplayName: from.displayName,
            fromPhotoURL: from.photoURL,
            toUserId: to.id,
            status: .pending,
            createdAt: Date()
        )
        
        let requestData: [String: Any] = [
            "id": request.id,
            "fromUserId": request.fromUserId,
            "fromUsername": request.fromUsername,
            "fromDisplayName": request.fromDisplayName ?? "",
            "fromPhotoURL": request.fromPhotoURL ?? "",
            "toUserId": request.toUserId,
            "status": request.status.rawValue,
            "createdAt": request.createdAt.timeIntervalSince1970
        ]
        
        try await database.child("friendRequests").child(requestId).setValue(requestData)
        print("✅ Arkadaşlık isteği kaydedildi")
    }
    
    // Arkadaşlık isteğini kabul et
    func acceptFriendRequest(_ request: FriendRequest) async throws {
        print("✅ Arkadaşlık isteği kabul ediliyor: \(request.id)")
        
        // İsteği kabul edildi olarak güncelle
        try await database.child("friendRequests").child(request.id).child("status").setValue("accepted")
        
        // Her iki kullanıcının arkadaş listesine ekle
        try await database.child("friends").child(request.fromUserId).child(request.toUserId).setValue(true)
        try await database.child("friends").child(request.toUserId).child(request.fromUserId).setValue(true)
        
        print("✅ Arkadaşlık oluşturuldu")
    }
    
    // Arkadaşlık isteğini reddet
    func rejectFriendRequest(_ request: FriendRequest) async throws {
        print("❌ Arkadaşlık isteği reddediliyor: \(request.id)")
        try await database.child("friendRequests").child(request.id).child("status").setValue("rejected")
    }
    
    // Arkadaşı kaldır
    func removeFriend(userId: String, friendId: String) async throws {
        print("🗑️ Arkadaş kaldırılıyor: \(userId) <-> \(friendId)")
        
        // Her iki taraftan da arkadaşlığı kaldır
        try await database.child("friends").child(userId).child(friendId).removeValue()
        try await database.child("friends").child(friendId).child(userId).removeValue()
        
        print("✅ Arkadaşlık kaldırıldı")
    }
    
    // Gelen arkadaşlık isteklerini getir (SADECE KENDİNE GELEN)
    func fetchIncomingFriendRequests(for userId: String) async throws -> [FriendRequest] {
        print("📥 Gelen arkadaşlık istekleri getiriliyor: \(userId)")
        
        let snapshot = try await database.child("friendRequests").getData()
        
        guard let requestsData = snapshot.value as? [String: [String: Any]] else {
            print("📥 Hiç istek yok")
            return []
        }
        
        var requests: [FriendRequest] = []
        
        for (_, requestData) in requestsData {
            guard let id = requestData["id"] as? String,
                  let fromUserId = requestData["fromUserId"] as? String,
                  let fromUsername = requestData["fromUsername"] as? String,
                  let toUserId = requestData["toUserId"] as? String,
                  let statusRaw = requestData["status"] as? String,
                  let status = FriendRequest.RequestStatus(rawValue: statusRaw),
                  let createdAtTimestamp = requestData["createdAt"] as? TimeInterval else {
                continue
            }
            
            // SADECE BANA GELEN VE PENDING OLAN İSTEKLER
            if toUserId == userId && status == .pending {
                let request = FriendRequest(
                    id: id,
                    fromUserId: fromUserId,
                    fromUsername: fromUsername,
                    fromDisplayName: requestData["fromDisplayName"] as? String,
                    fromPhotoURL: requestData["fromPhotoURL"] as? String,
                    toUserId: toUserId,
                    status: status,
                    createdAt: Date(timeIntervalSince1970: createdAtTimestamp)
                )
                
                requests.append(request)
                print("✅ İstek eklendi: \(fromUsername) -> \(toUserId)")
            }
        }
        
        let sortedRequests = requests.sorted { $0.createdAt > $1.createdAt }
        print("📥 Toplam \(sortedRequests.count) gelen istek")
        return sortedRequests
    }
    
    // Arkadaş mı kontrol et
    func isFriend(userId: String, friendId: String) async throws -> Bool {
        let snapshot = try await database.child("friends").child(userId).child(friendId).getData()
        return snapshot.exists()
    }
    
    // Arkadaş isteği gönderilmiş mi kontrol et
    func hasSentFriendRequest(from userId: String, to friendId: String) async throws -> Bool {
        let requestId = "\(userId)_\(friendId)"
        let snapshot = try await database.child("friendRequests").child(requestId).getData()
        
        if let requestData = snapshot.value as? [String: Any],
           let statusRaw = requestData["status"] as? String,
           let status = FriendRequest.RequestStatus(rawValue: statusRaw) {
            return status == .pending
        }
        
        return false
    }
    
    // Arkadaşları getir
    func fetchFriends(for userId: String) async throws -> [User] {
        print("👥 Arkadaşlar getiriliyor: \(userId)")
        
        let snapshot = try await database.child("friends").child(userId).getData()
        
        guard let friendIds = snapshot.value as? [String: Bool] else {
            print("👥 Hiç arkadaş yok")
            return []
        }
        
        print("📊 \(friendIds.count) arkadaş ID'si bulundu")
        var friends: [User] = []
        
        for (friendId, _) in friendIds {
            do {
                let friend = try await fetchUser(uid: friendId)
                friends.append(friend)
                print("✅ Arkadaş yüklendi: \(friend.username)")
            } catch {
                print("⚠️ Arkadaş yüklenemedi: \(friendId) - \(error.localizedDescription)")
            }
        }
        
        print("✅ Toplam \(friends.count) arkadaş döndürülüyor")
        return friends
    }
    
    // Kullanıcıyı getir (helper)
    private func fetchUser(uid: String) async throws -> User {
        let snapshot = try await database.child("users").child(uid).getData()
        
        guard let userData = snapshot.value as? [String: Any],
              let email = userData["email"] as? String,
              let username = userData["username"] as? String,
              let createdAtTimestamp = userData["createdAt"] as? TimeInterval else {
            throw NSError(domain: "FriendService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı verisi alınamadı"])
        }
        
        var privacySettings = PrivacySettings()
        if let privacyData = userData["privacySettings"] as? [String: Any],
           let whoCanMessageRaw = privacyData["whoCanMessage"] as? String,
           let whoCanMessage = PrivacySettings.MessagePrivacy(rawValue: whoCanMessageRaw) {
            privacySettings.whoCanMessage = whoCanMessage
        }
        
        return User(
            id: uid,
            email: email,
            username: username,
            displayName: userData["displayName"] as? String,
            photoURL: userData["photoURL"] as? String,
            createdAt: Date(timeIntervalSince1970: createdAtTimestamp),
            lastSeen: (userData["lastSeen"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) },
            isOnline: userData["isOnline"] as? Bool ?? false,
            privacySettings: privacySettings
        )
    }
}
