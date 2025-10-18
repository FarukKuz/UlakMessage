//
//  UserService.swift
//  UlakMessage
//
//  Konum: Services/UserService.swift
//

import Foundation
import FirebaseDatabase
import FirebaseAuth

class UserService {
    static let shared = UserService()
    private let database = Database.database().reference()
    private var presenceRef: DatabaseReference?
    
    private init() {}
    
    // Kullanıcı bilgilerini getir
    func getUser(userId: String) async throws -> User {
        let snapshot = try await database.child("users").child(userId).getData()
        
        guard snapshot.exists(),
              let userData = snapshot.value as? [String: Any] else {
            throw NSError(domain: "UserService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı bulunamadı"])
        }
        
        return try parseUser(userId: userId, data: userData)
    }
    
    // 🔥 REALTIME KULLANICI BİLGİSİ DİNLE (Online/Offline, LastSeen)
    func observeUser(userId: String, completion: @escaping (User?) -> Void) {
        database.child("users").child(userId).observe(.value) { snapshot in
            guard snapshot.exists(),
                  let userData = snapshot.value as? [String: Any] else {
                completion(nil)
                return
            }
            
            do {
                let user = try self.parseUser(userId: userId, data: userData)
                completion(user)
            } catch {
                print("❌ User parse hatası: \(error)")
                completion(nil)
            }
        }
    }
    
    // Dinlemeyi durdur
    func removeUserObserver(userId: String) {
        database.child("users").child(userId).removeAllObservers()
    }
    
    // 👁️ PRESENCE TRACKING - Kullanıcı online durumunu başlat
    func startPresenceTracking(userId: String) {
        print("👁️ Presence tracking başlatıldı: \(userId)")
        
        presenceRef = database.child("users").child(userId)
        
        // Firebase'in özel .info/connected node'u
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        
        connectedRef.observe(.value) { [weak self] snapshot in
            guard let self = self,
                  let connected = snapshot.value as? Bool,
                  connected else {
                return
            }
            
            // Bağlantı kesildiğinde otomatik çalışacak
            self.presenceRef?.onDisconnectUpdateChildValues([
                "isOnline": false,
                "lastSeen": ServerValue.timestamp()
            ])
            
            // Şu anda online
            self.presenceRef?.updateChildValues([
                "isOnline": true,
                "lastSeen": ServerValue.timestamp()
            ])
            
            print("✅ Online durumu güncellendi")
        }
    }
    
    // 🛑 PRESENCE TRACKING - Kullanıcı offline olduğunda
    func stopPresenceTracking(userId: String) {
        print("🛑 Presence tracking durduruldu: \(userId)")
        
        database.child("users").child(userId).updateChildValues([
            "isOnline": false,
            "lastSeen": ServerValue.timestamp()
        ])
        
        Database.database().reference(withPath: ".info/connected").removeAllObservers()
        presenceRef = nil
    }
    
    // 🔄 Son görülme zamanını manuel güncelle
    func updateLastSeen(userId: String) {
        database.child("users").child(userId).updateChildValues([
            "lastSeen": ServerValue.timestamp()
        ])
    }
    
    private func parseUser(userId: String, data: [String: Any]) throws -> User {
        guard let email = data["email"] as? String,
              let username = data["username"] as? String else {
            throw NSError(domain: "UserService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User parse hatası"])
        }
        
        let displayName = data["displayName"] as? String
        let isOnline = data["isOnline"] as? Bool ?? false
        let lastSeenTimestamp = data["lastSeen"] as? TimeInterval
        let createdAtTimestamp = data["createdAt"] as? TimeInterval ?? Date().timeIntervalSince1970
        
        // PrivacySettings parse - DÜZELTME YAPILDI
        var privacySettings = PrivacySettings()
        if let privacyData = data["privacySettings"] as? [String: Any],
           let whoCanMessageString = privacyData["whoCanMessage"] as? String,
           let whoCanMessage = PrivacySettings.MessagePrivacy(rawValue: whoCanMessageString) {
            privacySettings = PrivacySettings(whoCanMessage: whoCanMessage)
        }
        
        return User(
            id: userId,
            email: email,
            username: username,
            displayName: displayName,
            photoURL: data["photoURL"] as? String,
            createdAt: Date(timeIntervalSince1970: createdAtTimestamp),
            lastSeen: lastSeenTimestamp.map { Date(timeIntervalSince1970: $0) },
            isOnline: isOnline,
            privacySettings: privacySettings
        )
    }
}
