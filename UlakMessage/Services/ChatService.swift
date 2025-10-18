//
//  ChatService.swift
//  UlakMessage
//
//  Konum: Services/ChatService.swift
//

import Foundation
import FirebaseDatabase

class ChatService {
    static let shared = ChatService()
    
    private let database = Database.database().reference()
    
    private init() {}
    
    // Chat ID oluştur (iki kullanıcı arasında)
    func generateChatId(userId1: String, userId2: String) -> String {
        let sortedIds = [userId1, userId2].sorted()
        return "\(sortedIds[0])_\(sortedIds[1])"
    }
    
    // Chat var mı kontrol et veya oluştur
    func getOrCreateChat(currentUser: User, otherUser: User) async throws -> Chat {
        let chatId = generateChatId(userId1: currentUser.id, userId2: otherUser.id)
        
        print("💬 Chat ID: \(chatId)")
        print("👤 Current User: \(currentUser.username) (\(currentUser.id))")
        print("👤 Other User: \(otherUser.username) (\(otherUser.id))")
        
        // Önce var mı kontrol et
        do {
            let snapshot = try await database.child("chats").child(chatId).getData()
            
            if snapshot.exists() {
                print("✅ Chat zaten mevcut")
                if let chatData = snapshot.value as? [String: Any] {
                    return try parseChat(chatId: chatId, data: chatData)
                }
            }
            
            // Yoksa oluştur
            print("🆕 Yeni chat oluşturuluyor...")
            let chat = Chat(
                id: chatId,
                participants: [currentUser.id, otherUser.id],
                participantUsernames: [
                    currentUser.id: currentUser.username,
                    otherUser.id: otherUser.username
                ],
                participantDisplayNames: [
                    currentUser.id: currentUser.displayName ?? "",
                    otherUser.id: otherUser.displayName ?? ""
                ],
                createdAt: Date()
            )
            
            try await saveChat(chat)
            print("✅ Chat başarıyla oluşturuldu")
            return chat
            
        } catch {
            print("❌ Chat oluşturma hatası: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Chat'i kaydet
    private func saveChat(_ chat: Chat) async throws {
        print("💾 Chat kaydediliyor: \(chat.id)")
        
        let chatData: [String: Any] = [
            "id": chat.id,
            "participants": chat.participants,
            "participantUsernames": chat.participantUsernames,
            "participantDisplayNames": chat.participantDisplayNames,
            "lastMessage": chat.lastMessage ?? "",
            "lastMessageTimestamp": chat.lastMessageTimestamp?.timeIntervalSince1970 ?? 0,
            "lastMessageSenderId": chat.lastMessageSenderId ?? "",
            "createdAt": chat.createdAt.timeIntervalSince1970
        ]
        
        try await database.child("chats").child(chat.id).setValue(chatData)
        print("✅ Chat kaydedildi: /chats/\(chat.id)")
        
        // Her kullanıcının chat listesine ekle
        for participantId in chat.participants {
            try await database.child("userChats").child(participantId).child(chat.id).setValue(true)
            print("✅ Chat kullanıcıya eklendi: /userChats/\(participantId)/\(chat.id)")
        }
    }
    
    // Kullanıcının chat'lerini getir
    func fetchUserChats(userId: String) async throws -> [Chat] {
        print("📋 Chat'ler getiriliyor: \(userId)")
        
        let snapshot = try await database.child("userChats").child(userId).getData()
        
        guard let chatIds = snapshot.value as? [String: Bool] else {
            print("📋 Hiç chat yok")
            return []
        }
        
        print("📊 Toplam \(chatIds.count) chat bulundu")
        var chats: [Chat] = []
        
        for (chatId, _) in chatIds {
            do {
                let chat = try await fetchChat(chatId: chatId)
                chats.append(chat)
                print("✅ Chat yüklendi: \(chatId)")
            } catch {
                print("⚠️ Chat yüklenemedi: \(chatId) - \(error.localizedDescription)")
            }
        }
        
        // Son mesaja göre sırala
        chats.sort { (chat1, chat2) -> Bool in
            guard let time1 = chat1.lastMessageTimestamp,
                  let time2 = chat2.lastMessageTimestamp else {
                return chat1.createdAt > chat2.createdAt
            }
            return time1 > time2
        }
        
        print("✅ Toplam \(chats.count) chat döndürülüyor")
        return chats
    }
    
    // Tek bir chat'i getir
    func fetchChat(chatId: String) async throws -> Chat {
        let snapshot = try await database.child("chats").child(chatId).getData()
        
        guard snapshot.exists() else {
            print("❌ Chat bulunamadı: \(chatId)")
            throw NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Chat bulunamadı"])
        }
        
        guard let chatData = snapshot.value as? [String: Any] else {
            print("❌ Chat verisi parse edilemedi: \(chatId)")
            throw NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Chat verisi parse edilemedi"])
        }
        
        return try parseChat(chatId: chatId, data: chatData)
    }
    
    // Chat'i parse et
    private func parseChat(chatId: String, data: [String: Any]) throws -> Chat {
        guard let participants = data["participants"] as? [String],
              let participantUsernames = data["participantUsernames"] as? [String: String],
              let participantDisplayNames = data["participantDisplayNames"] as? [String: String],
              let createdAtTimestamp = data["createdAt"] as? TimeInterval else {
            print("❌ Chat parse hatası: \(chatId)")
            throw NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Chat parse edilemedi"])
        }
        
        let lastMessageTimestamp = (data["lastMessageTimestamp"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) }
        
        return Chat(
            id: chatId,
            participants: participants,
            participantUsernames: participantUsernames,
            participantDisplayNames: participantDisplayNames,
            lastMessage: data["lastMessage"] as? String,
            lastMessageTimestamp: lastMessageTimestamp,
            lastMessageSenderId: data["lastMessageSenderId"] as? String,
            createdAt: Date(timeIntervalSince1970: createdAtTimestamp)
        )
    }
    
    // Mesaj gönder
    func sendMessage(chat: Chat, sender: User, text: String) async throws {
        print("📤 Mesaj gönderiliyor...")
        print("💬 Chat ID: \(chat.id)")
        print("👤 Gönderen: \(sender.username)")
        print("📝 Mesaj: \(text)")
        
        let message = Message(
            chatId: chat.id,
            senderId: sender.id,
            senderUsername: sender.username,
            text: text,
            timestamp: Date(),
            isRead: false
        )
        
        let messageData: [String: Any] = [
            "id": message.id,
            "chatId": message.chatId,
            "senderId": message.senderId,
            "senderUsername": message.senderUsername,
            "text": message.text,
            "timestamp": message.timestamp.timeIntervalSince1970,
            "isRead": message.isRead
        ]
        
        // Mesajı kaydet
        do {
            try await database.child("messages").child(chat.id).child(message.id).setValue(messageData)
            print("✅ Mesaj kaydedildi: /messages/\(chat.id)/\(message.id)")
        } catch {
            print("❌ Mesaj kaydetme hatası: \(error.localizedDescription)")
            throw error
        }
        
        // Chat'in son mesajını güncelle
        let chatUpdates: [String: Any] = [
            "lastMessage": text,
            "lastMessageTimestamp": message.timestamp.timeIntervalSince1970,
            "lastMessageSenderId": sender.id
        ]
        
        do {
            try await database.child("chats").child(chat.id).updateChildValues(chatUpdates)
            print("✅ Chat güncellendi: /chats/\(chat.id)")
        } catch {
            print("❌ Chat güncelleme hatası: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Mesajları dinle (realtime)
    func observeMessages(chatId: String, completion: @escaping ([Message]) -> Void) {
        print("👂 Mesajlar dinleniyor: \(chatId)")
        
        database.child("messages").child(chatId)
            .queryOrdered(byChild: "timestamp")
            .observe(.value) { snapshot in
                print("📦 Mesaj snapshot alındı: \(snapshot.childrenCount) mesaj")
                
                guard let messagesData = snapshot.value as? [String: [String: Any]] else {
                    print("⚠️ Mesaj verisi yok")
                    completion([])
                    return
                }
                
                var messages: [Message] = []
                
                for (messageId, messageData) in messagesData {
                    do {
                        let message = try self.parseMessage(data: messageData)
                        messages.append(message)
                    } catch {
                        print("⚠️ Mesaj parse edilemedi: \(messageId)")
                    }
                }
                
                messages.sort { $0.timestamp < $1.timestamp }
                print("✅ \(messages.count) mesaj yüklendi")
                completion(messages)
            }
    }
    
    // Mesajları dinlemeyi durdur
    func removeObserver(chatId: String) {
        print("🛑 Mesaj dinleme durduruldu: \(chatId)")
        database.child("messages").child(chatId).removeAllObservers()
    }
    
    // Mesajı parse et
    private func parseMessage(data: [String: Any]) throws -> Message {
        guard let id = data["id"] as? String,
              let chatId = data["chatId"] as? String,
              let senderId = data["senderId"] as? String,
              let senderUsername = data["senderUsername"] as? String,
              let text = data["text"] as? String,
              let timestampValue = data["timestamp"] as? TimeInterval else {
            throw NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mesaj parse edilemedi"])
        }
        
        return Message(
            id: id,
            chatId: chatId,
            senderId: senderId,
            senderUsername: senderUsername,
            text: text,
            timestamp: Date(timeIntervalSince1970: timestampValue),
            isRead: data["isRead"] as? Bool ?? false
        )
    }
}
