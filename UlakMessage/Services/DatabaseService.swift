//
//  DatabaseService.swift
//  UlakMessage
//
//  Konum: Services/DatabaseService.swift
//

import Foundation
import FirebaseDatabase

class DatabaseService {
    static let shared = DatabaseService()
    
    private let database = Database.database().reference()
    
    private init() {
        // Bağlantı durumunu kontrol et
        checkConnection()
    }
    
    private func checkConnection() {
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value) { snapshot in
            if snapshot.value as? Bool == true {
                print("✅ Firebase'e BAĞLANDI")
            } else {
                print("❌ Firebase BAĞLANTI YOK")
            }
        }
    }
    
    // Kullanıcı bilgilerini güncelle
    func updateUserProfile(uid: String, displayName: String?, photoURL: String?) async throws {
        var updates: [String: Any] = [:]
        
        if let displayName = displayName {
            updates["displayName"] = displayName
        }
        
        if let photoURL = photoURL {
            updates["photoURL"] = photoURL
        }
        
        if !updates.isEmpty {
            try await database.child("users").child(uid).updateChildValues(updates)
        }
    }
    
    // Privacy settings güncelle
    func updatePrivacySettings(uid: String, settings: PrivacySettings) async throws {
        let privacyData: [String: Any] = [
            "whoCanMessage": settings.whoCanMessage.rawValue
        ]
        
        try await database.child("users").child(uid).child("privacySettings").setValue(privacyData)
    }
    
    // Kullanıcı adına göre kullanıcı ara - GELİŞTİRİLMİŞ VERSİYON
    func searchUsersByUsername(_ query: String, currentUserId: String) async throws -> [User] {
        print("🔍 Arama sorgusu: '\(query)' - Kullanıcı ID: \(currentUserId)")
        
        // Bağlantı kontrolü
        let connectionCheck = try await checkFirebaseConnection()
        if !connectionCheck {
            print("❌ Firebase bağlantısı yok, tekrar deneniyor...")
            // 2 saniye bekle ve tekrar dene
            try await Task.sleep(nanoseconds: 2_000_000_000)
        }
        
        do {
            print("📡 Firebase'den veri çekiliyor...")
            
            // observeSingleEvent kullanarak veri çek
            let users = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[User], Error>) in
                database.child("users").observeSingleEvent(of: .value) { snapshot in
                    print("📦 Snapshot alındı: exists = \(snapshot.exists())")
                    
                    if !snapshot.exists() {
                        print("❌ Veritabanında hiç kullanıcı yok!")
                        continuation.resume(returning: [])
                        return
                    }
                    
                    guard let usersData = snapshot.value as? [String: [String: Any]] else {
                        print("❌ Kullanıcı verisi parse edilemedi")
                        continuation.resume(returning: [])
                        return
                    }
                    
                    print("📊 Toplam kullanıcı sayısı: \(usersData.count)")
                    print("📋 Kullanıcı ID'leri: \(usersData.keys.joined(separator: ", "))")
                    
                    var users: [User] = []
                    let lowercasedQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    for (uid, userData) in usersData {
                        print("👤 İşleniyor: \(uid)")
                        
                        if uid == currentUserId {
                            print("⏭️ Kendi kullanıcısı atlandı")
                            continue
                        }
                        
                        guard let email = userData["email"] as? String,
                              let username = userData["username"] as? String,
                              let createdAtTimestamp = userData["createdAt"] as? TimeInterval else {
                            print("❌ Eksik veri: \(uid)")
                            continue
                        }
                        
                        print("✅ Geçerli: @\(username)")
                        
                        // Username'de arama yap
                        let usernameLower = username.lowercased()
                        print("🔎 '\(usernameLower)' içinde '\(lowercasedQuery)' aranıyor")
                        
                        if usernameLower.contains(lowercasedQuery) {
                            print("✅✅✅ EŞLEŞME: @\(username)")
                            
                            var privacySettings = PrivacySettings()
                            if let privacyData = userData["privacySettings"] as? [String: Any],
                               let whoCanMessageRaw = privacyData["whoCanMessage"] as? String,
                               let whoCanMessage = PrivacySettings.MessagePrivacy(rawValue: whoCanMessageRaw) {
                                privacySettings.whoCanMessage = whoCanMessage
                            }
                            
                            let user = User(
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
                            
                            users.append(user)
                        }
                    }
                    
                    print("📋 Toplam bulunan: \(users.count)")
                    if !users.isEmpty {
                        print("✅ Bulunanlar: \(users.map { "@" + $0.username }.joined(separator: ", "))")
                    }
                    
                    continuation.resume(returning: users)
                    
                } withCancel: { error in
                    print("❌❌❌ HATA: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
            
            return users
            
        } catch {
            print("❌❌❌ HATA: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Firebase bağlantı kontrolü
    private func checkFirebaseConnection() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            let connectedRef = Database.database().reference(withPath: ".info/connected")
            connectedRef.observeSingleEvent(of: .value) { snapshot in
                let connected = snapshot.value as? Bool ?? false
                print(connected ? "✅ Bağlantı OK" : "❌ Bağlantı YOK")
                continuation.resume(returning: connected)
            } withCancel: { error in
                continuation.resume(throwing: error)
            }
        }
    }
    
    // Tüm kullanıcıları getir
    func fetchAllUsers(excludingUID: String) async throws -> [User] {
        return try await withCheckedThrowingContinuation { continuation in
            database.child("users").observeSingleEvent(of: .value) { snapshot in
                guard let usersData = snapshot.value as? [String: [String: Any]] else {
                    continuation.resume(returning: [])
                    return
                }
                
                var users: [User] = []
                
                for (uid, userData) in usersData {
                    if uid == excludingUID { continue }
                    
                    guard let email = userData["email"] as? String,
                          let username = userData["username"] as? String,
                          let createdAtTimestamp = userData["createdAt"] as? TimeInterval else {
                        continue
                    }
                    
                    var privacySettings = PrivacySettings()
                    if let privacyData = userData["privacySettings"] as? [String: Any],
                       let whoCanMessageRaw = privacyData["whoCanMessage"] as? String,
                       let whoCanMessage = PrivacySettings.MessagePrivacy(rawValue: whoCanMessageRaw) {
                        privacySettings.whoCanMessage = whoCanMessage
                    }
                    
                    let user = User(
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
                    
                    users.append(user)
                }
                
                continuation.resume(returning: users)
            } withCancel: { error in
                continuation.resume(throwing: error)
            }
        }
    }
}
