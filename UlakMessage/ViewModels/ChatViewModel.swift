//
//  ChatViewModel.swift
//  UlakMessage
//
//  Konum: ViewModels/ChatViewModel.swift
//

import SwiftUI
import Combine
import FirebaseDatabase

@MainActor
class ChatViewModel: ObservableObject {
    @Published var chats: [Chat] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let chatService = ChatService.shared
    private var chatListeners: [String: DatabaseHandle] = [:]
    private let database = Database.database().reference()
    
    // Kullanıcının chat'lerini getir ve dinle
    func fetchChats(for userId: String) async {
        print("🔄 Chat'ler yenileniyor: \(userId)")
        isLoading = true
        errorMessage = nil
        
        do {
            chats = try await chatService.fetchUserChats(userId: userId)
            
            // Her chat için realtime güncelleme dinle
            startObservingChats(for: userId)
        } catch {
            print("❌ Chat yükleme hatası: \(error.localizedDescription)")
            errorMessage = "Chat'ler yüklenemedi: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // Chat'leri realtime dinle
    private func startObservingChats(for userId: String) {
        print("👂 Chat güncellemeleri dinleniyor...")
        
        let userChatsRef = database.child("userChats").child(userId)
        
        userChatsRef.observe(.childAdded) { [weak self] snapshot in
            guard let self = self else { return }
            let chatId = snapshot.key
            
            Task { @MainActor in
                print("🆕 Yeni chat eklendi: \(chatId)")
                await self.loadAndAddChat(chatId: chatId)
            }
        }
        
        // Chat güncellemelerini dinle
        database.child("chats").observe(.childChanged) { [weak self] snapshot in
            guard let self = self,
                  let _ = snapshot.value as? [String: Any] else { return }
            
            let chatId = snapshot.key
            
            Task { @MainActor in
                print("🔄 Chat güncellendi: \(chatId)")
                await self.reloadChat(chatId: chatId)
            }
        }
    }

    // Chat'i yeniden yükle
    private func reloadChat(chatId: String) async {
        do {
            let updatedChat = try await chatService.fetchChat(chatId: chatId)
            if let index = self.chats.firstIndex(where: { $0.id == chatId }) {
                self.chats[index] = updatedChat
                
                // Sıralamayı güncelle
                self.chats.sort { (chat1, chat2) -> Bool in
                    guard let time1 = chat1.lastMessageTimestamp,
                          let time2 = chat2.lastMessageTimestamp else {
                        return chat1.createdAt > chat2.createdAt
                    }
                    return time1 > time2
                }
            }
        } catch {
            print("⚠️ Chat güncelleme hatası: \(error.localizedDescription)")
        }
    }
    
    private func loadAndAddChat(chatId: String) async {
        do {
            let chat = try await chatService.fetchChat(chatId: chatId)
            if !chats.contains(where: { $0.id == chatId }) {
                chats.append(chat)
                
                // Sıralamayı güncelle
                chats.sort { (chat1, chat2) -> Bool in
                    guard let time1 = chat1.lastMessageTimestamp,
                          let time2 = chat2.lastMessageTimestamp else {
                        return chat1.createdAt > chat2.createdAt
                    }
                    return time1 > time2
                }
            }
        } catch {
            print("⚠️ Chat yükleme hatası: \(error.localizedDescription)")
        }
    }
    
    // Chat aç veya oluştur
    func getOrCreateChat(currentUser: User, otherUser: User) async -> Chat? {
        print("🔍 Chat açılıyor veya oluşturuluyor...")
        do {
            let chat = try await chatService.getOrCreateChat(currentUser: currentUser, otherUser: otherUser)
            
            // Eğer listede yoksa ekle
            if !chats.contains(where: { $0.id == chat.id }) {
                chats.append(chat)
            }
            
            return chat
        } catch {
            print("❌ Chat açma hatası: \(error.localizedDescription)")
            errorMessage = "Chat oluşturulamadı: \(error.localizedDescription)"
            return nil
        }
    }
    
    // Dinlemeyi durdur - nonisolated
    nonisolated func stopObserving() {
        Task { @MainActor in
            let db = Database.database().reference()
            db.child("chats").removeAllObservers()
            db.child("userChats").removeAllObservers()
            print("🛑 Chat dinleme durduruldu")
        }
    }
    
    deinit {
        stopObserving()
    }
}
