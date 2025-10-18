//
//  MessageViewModel.swift
//  UlakMessage
//
//  Konum: ViewModels/MessageViewModel.swift
//

import SwiftUI
import Combine

@MainActor
class MessageViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSending = false
    
    private let chatService = ChatService.shared
    private let observingChatId: Box<String?>
    
    init() {
        self.observingChatId = Box(nil)
    }
    
    // Mesajları dinlemeye başla
    func startObserving(chatId: String) {
        print("👂 Mesaj dinleme başlatıldı: \(chatId)")
        observingChatId.value = chatId
        
        chatService.observeMessages(chatId: chatId) { [weak self] messages in
            Task { @MainActor in
                self?.messages = messages
                print("📬 \(messages.count) mesaj güncellendi")
            }
        }
    }
    
    // Mesaj gönder
    func sendMessage(chat: Chat, sender: User, text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("⚠️ Boş mesaj gönderilemez")
            return
        }
        
        print("📤 Mesaj gönderiliyor: \(text)")
        isSending = true
        errorMessage = nil
        
        do {
            try await chatService.sendMessage(chat: chat, sender: sender, text: text)
            print("✅ Mesaj gönderildi")
        } catch {
            print("❌ Mesaj gönderme hatası: \(error.localizedDescription)")
            errorMessage = "Mesaj gönderilemedi: \(error.localizedDescription)"
        }
        
        isSending = false
    }
    
    // Dinlemeyi durdur
    func stopObserving() {
        if let chatId = observingChatId.value {
            print("🛑 Mesaj dinleme durduruldu: \(chatId)")
            chatService.removeObserver(chatId: chatId)
        }
    }
    
    deinit {
        if let chatId = observingChatId.value {
            ChatService.shared.removeObserver(chatId: chatId)
        }
    }
}

// Thread-safe wrapper class
final class Box<T> {
    var value: T
    
    init(_ value: T) {
        self.value = value
    }
}
