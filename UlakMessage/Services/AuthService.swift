//
//  AuthService.swift
//  UlakMessage
//
//  Konum: Services/AuthService.swift
//

import Foundation
import FirebaseAuth
import FirebaseDatabase

class AuthService {
    static let shared = AuthService()
    
    private let auth = Auth.auth()
    private let database = Database.database().reference()
    
    private init() {}
    
    // Kullanıcı oturumunu kontrol et
    func checkAuthStatus() async throws -> User? {
        guard let firebaseUser = auth.currentUser else {
            return nil
        }
        
        print("🔐 Oturum kontrolü: \(firebaseUser.uid)")
        return try await fetchUser(uid: firebaseUser.uid)
    }
    
    // Kullanıcı adı müsait mi kontrol et
    func isUsernameAvailable(_ username: String) async throws -> Bool {
        let snapshot = try await database.child("usernames").child(username.lowercased()).getData()
        return !snapshot.exists()
    }
    
    // Kullanıcı kaydı
    func signUp(email: String, password: String, username: String, displayName: String?) async throws -> User {
        // Kullanıcı adı kontrolü
        let usernameAvailable = try await isUsernameAvailable(username)
        guard usernameAvailable else {
            throw NSError(domain: "AuthService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Bu kullanıcı adı zaten kullanılıyor"])
        }
        
        let result = try await auth.createUser(withEmail: email, password: password)
        
        let user = User(
            id: result.user.uid,
            email: email,
            username: username,
            displayName: displayName,
            createdAt: Date(),
            isOnline: true,
            privacySettings: PrivacySettings()
        )
        
        // Veritabanına kullanıcı bilgilerini kaydet
        try await saveUserToDatabase(user)
        
        // Kullanıcı adını kaydet (eşsiz olması için)
        try await database.child("usernames").child(username.lowercased()).setValue(result.user.uid)
            
        return user
    }
    
    // Giriş yap
    func signIn(email: String, password: String) async throws -> User {
        print("🔑 Giriş denemesi: \(email)")
        let result = try await auth.signIn(withEmail: email, password: password)
        
        print("✅ Firebase Auth başarılı: \(result.user.uid)")
        
        // Kullanıcıyı veritabanından getir
        let user = try await fetchUser(uid: result.user.uid)
        
        // Kullanıcıyı online yap
        try await updateUserOnlineStatus(uid: result.user.uid, isOnline: true)
        
        // Presence tracking başlat
        UserService.shared.startPresenceTracking(userId: user.id)
    
        return user
    }
    
    // Çıkış yap
    func signOut() throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Önce offline yap
        UserService.shared.stopPresenceTracking(userId: userId)
        
        // Sonra sign out
        try Auth.auth().signOut()
    }
    
    // Kullanıcıyı veritabanına kaydet
    private func saveUserToDatabase(_ user: User) async throws {
        let userData: [String: Any] = [
            "id": user.id,
            "email": user.email,
            "username": user.username,
            "displayName": user.displayName ?? "",
            "photoURL": user.photoURL ?? "",
            "createdAt": user.createdAt.timeIntervalSince1970,
            "isOnline": user.isOnline,
            "privacySettings": [
                "whoCanMessage": user.privacySettings.whoCanMessage.rawValue
            ]
        ]
        
        try await database.child("users").child(user.id).setValue(userData)
    }
    
    // Kullanıcıyı veritabanından getir - DÜZELTİLMİŞ
    private func fetchUser(uid: String) async throws -> User {
        print("📡 Kullanıcı bilgileri getiriliyor: \(uid)")
        
        // Doğru path: /users/{uid}
        let snapshot = try await database.child("users").child(uid).getData()
        
        guard snapshot.exists() else {
            print("❌ Kullanıcı veritabanında bulunamadı: \(uid)")
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı veritabanında bulunamadı"])
        }
        
        guard let userData = snapshot.value as? [String: Any] else {
            print("❌ Kullanıcı verisi parse edilemedi")
            print("📦 Snapshot value: \(snapshot.value ?? "nil")")
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı verisi parse edilemedi"])
        }
        
        print("📦 Kullanıcı verisi: \(userData)")
        
        // Email kontrolü
        guard let email = userData["email"] as? String else {
            print("❌ Email bulunamadı")
            print("📋 Mevcut keys: \(userData.keys)")
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı email'i bulunamadı"])
        }
        
        // Username kontrolü - YOKSA OTOMATİK OLUŞTUR
        var username: String
        if let existingUsername = userData["username"] as? String, !existingUsername.isEmpty {
            username = existingUsername
            print("✅ Username mevcut: \(username)")
        } else {
            print("⚠️ Username yok, otomatik oluşturuluyor...")
            // Email'den username oluştur veya UID kullan
            let emailPrefix = email.components(separatedBy: "@").first ?? "user"
            username = "\(emailPrefix)\(String(uid.prefix(4)))"
            
            // Veritabanına kaydet
            try await database.child("users").child(uid).child("username").setValue(username)
            try await database.child("usernames").child(username.lowercased()).setValue(uid)
            
            print("✅ Yeni username oluşturuldu ve kaydedildi: \(username)")
        }
        
        // CreatedAt kontrolü
        let createdAtTimestamp: TimeInterval
        if let timestamp = userData["createdAt"] as? TimeInterval {
            createdAtTimestamp = timestamp
        } else {
            print("⚠️ CreatedAt yok, şimdi oluşturuluyor...")
            createdAtTimestamp = Date().timeIntervalSince1970
            try await database.child("users").child(uid).child("createdAt").setValue(createdAtTimestamp)
        }
        
        // Privacy settings kontrolü
        var privacySettings = PrivacySettings()
        if let privacyData = userData["privacySettings"] as? [String: Any],
           let whoCanMessageRaw = privacyData["whoCanMessage"] as? String,
           let whoCanMessage = PrivacySettings.MessagePrivacy(rawValue: whoCanMessageRaw) {
            privacySettings.whoCanMessage = whoCanMessage
        } else {
            print("⚠️ Privacy settings yok, varsayılan ayarlanıyor...")
            // Varsayılan privacy settings'i kaydet
            try await database.child("users").child(uid).child("privacySettings").setValue([
                "whoCanMessage": privacySettings.whoCanMessage.rawValue
            ])
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
        
        print("✅ Kullanıcı başarıyla yüklendi: @\(user.username)")
        return user
    }
    
    // Kullanıcı online durumunu güncelle
    private func updateUserOnlineStatus(uid: String, isOnline: Bool) async throws {
        let updates: [String: Any] = [
            "isOnline": isOnline,
            "lastSeen": Date().timeIntervalSince1970
        ]
        
        try await database.child("users").child(uid).updateChildValues(updates)
    }
}
