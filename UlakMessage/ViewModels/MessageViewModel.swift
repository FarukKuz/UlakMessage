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
    @Published var shouldScrollToBottom = false // Yeni mesaj kontrolü
    
    private let chatService = ChatService.shared
    private let observingChatId: Box<String?>
    private var initialLoadComplete = false
    
    init() {
        self.observingChatId = Box(nil)
    }
    
    // 🚀 OPTİMİZE EDİLMİŞ MESAJ DİNLEME
    func startObserving(chatId: String) {
        print("👂 Optimize mesaj dinleme başlatıldı: \(chatId)")
        observingChatId.value = chatId
        isLoading = true
        initialLoadComplete = false
        
        chatService.observeMessages(
            chatId: chatId,
            onInitialLoad: { [weak self] messages in
                Task { @MainActor in
                    self?.messages = messages
                    self?.isLoading = false
                    self?.initialLoadComplete = true
                    self?.shouldScrollToBottom = true
                    print("📬 İlk yükleme: \(messages.count) mesaj")
                }
            },
            onNewMessage: { [weak self] newMessage in
                Task { @MainActor in
                    guard let self = self, self.initialLoadComplete else { return }
                    
                    // Mesaj zaten varsa ekleme (중복 방지)
                    if !self.messages.contains(where: { $0.id == newMessage.id }) {
                        self.messages.append(newMessage)
                        self.shouldScrollToBottom = true
                        print("🆕 Yeni mesaj eklendi: \(newMessage.text)")
                    }
                }
            }
        )
    }
    
    // Mesaj gönder
    func sendMessage(chat: Chat, sender: User, text: String, type: MessageType = .text, mediaURL: String? = nil) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || type != .text else {
            print("⚠️ Boş mesaj gönderilemez")
            return
        }
        
        print("📤 Mesaj gönderiliyor: \(text)")
        isSending = true
        errorMessage = nil
        
        do {
            try await chatService.sendMessage(chat: chat, sender: sender, text: text, type: type, mediaURL: mediaURL)
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
