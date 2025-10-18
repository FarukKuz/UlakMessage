//
//  ChatDetailView.swift
//  UlakMessage
//
//  Konum: Views/Chat/ChatDetailView.swift
//

import SwiftUI
import FirebaseAuth

struct ChatDetailView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeViewModel: ThemeViewModel
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var messageViewModel = MessageViewModel()
    
    let chat: Chat
    let otherUserId: String
    let otherUsername: String
    let otherDisplayName: String?
    
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var authError: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
                .background(themeViewModel.currentTheme.borderColor)
            
            // Auth hata mesajı
            if let authError = authError {
                Text("⚠️ Kimlik doğrulama hatası: \(authError)")
                    .font(.caption)
                    .foregroundColor(themeViewModel.currentTheme.errorColor)
                    .padding()
                    .background(themeViewModel.currentTheme.errorColor.opacity(0.1))
            }
            
            // Mesajlar
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if messageViewModel.messages.isEmpty {
                            emptyStateView
                        } else {
                            ForEach(messageViewModel.messages) { message in
                                MessageBubbleView(
                                    message: message,
                                    isCurrentUser: message.senderId == authViewModel.currentUser?.id
                                )
                                .id(message.id)
                            }
                        }
                    }
                    .padding()
                }
                .onChange(of: messageViewModel.messages.count) { oldValue, newValue in
                    if let lastMessage = messageViewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onAppear {
                    if let lastMessage = messageViewModel.messages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            
            // Hata mesajı
            if let error = messageViewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(themeViewModel.currentTheme.errorColor)
                    .padding(.horizontal)
                    .padding(.vertical, 4)
            }
            
            // Mesaj input
            messageInputView
        }
        .background(themeViewModel.currentTheme.backgroundColor)
        .navigationBarHidden(true)
        .onAppear {
            checkAuthStatus()
            print("🎬 ChatDetailView açıldı")
            print("💬 Chat ID: \(chat.id)")
            print("👤 Karşı kullanıcı: \(otherUsername)")
            print("🔐 Current User ID: \(authViewModel.currentUser?.id ?? "nil")")
            print("🔐 Firebase Auth UID: \(Auth.auth().currentUser?.uid ?? "nil")")
            messageViewModel.startObserving(chatId: chat.id)
        }
        .onDisappear {
            print("👋 ChatDetailView kapandı")
            messageViewModel.stopObserving()
        }
    }
    
    // Auth durumunu kontrol et
    private func checkAuthStatus() {
        if Auth.auth().currentUser == nil {
            authError = "Oturum bulunamadı. Lütfen çıkış yapıp tekrar giriş yapın."
            print("❌ Firebase Auth kullanıcısı yok!")
        } else if authViewModel.currentUser == nil {
            authError = "Kullanıcı bilgisi bulunamadı."
            print("❌ AuthViewModel'de currentUser yok!")
        } else {
            print("✅ Auth durumu OK")
            print("   - Firebase UID: \(Auth.auth().currentUser!.uid)")
            print("   - App User ID: \(authViewModel.currentUser!.id)")
            print("   - Username: \(authViewModel.currentUser!.username)")
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 15) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 50))
                .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
            
            Text("Henüz mesaj yok")
                .font(.headline)
                .foregroundColor(themeViewModel.currentTheme.textColor)
            
            Text("İlk mesajı göndererek sohbete başlayın")
                .font(.subheadline)
                .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 50)
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack(spacing: 12) {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(themeViewModel.currentTheme.primaryColor)
            }
            
            // Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            themeViewModel.currentTheme.primaryColor,
                            themeViewModel.currentTheme.secondaryColor
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(otherDisplayName?.prefix(1) ?? otherUsername.prefix(1)).uppercased())
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(otherDisplayName ?? otherUsername)
                    .font(.headline)
                    .foregroundColor(themeViewModel.currentTheme.textColor)
                
                Text("@\(otherUsername)")
                    .font(.caption)
                    .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
            }
            
            Spacer()
        }
        .padding()
        .background(themeViewModel.currentTheme.backgroundColor)
    }
    
    // MARK: - Message Input
    private var messageInputView: some View {
        HStack(spacing: 12) {
            // Text field
            HStack {
                TextField("Mesaj yaz...", text: $messageText, axis: .vertical)
                    .foregroundColor(themeViewModel.currentTheme.textColor)
                    .lineLimit(1...5)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .focused($isTextFieldFocused)
                    .disabled(messageViewModel.isSending)
            }
            .background(themeViewModel.currentTheme.cardBackgroundColor)
            .cornerRadius(20)
            
            // Send button
            Button(action: sendMessage) {
                if messageViewModel.isSending {
                    ProgressView()
                        .tint(themeViewModel.currentTheme.primaryColor)
                        .frame(width: 32, height: 32)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(messageText.isEmpty ? themeViewModel.currentTheme.secondaryTextColor : themeViewModel.currentTheme.primaryColor)
                }
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || messageViewModel.isSending)
        }
        .padding()
        .background(themeViewModel.currentTheme.backgroundColor)
    }
    
    private func sendMessage() {
        guard Auth.auth().currentUser != nil else {
            print("❌ Firebase Auth kullanıcısı yok")
            authError = "Oturum bulunamadı. Lütfen çıkış yapıp tekrar giriş yapın."
            return
        }
        
        guard let currentUser = authViewModel.currentUser else {
            print("❌ Kullanıcı oturumu yok")
            authError = "Kullanıcı bilgisi bulunamadı."
            return
        }
        
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            print("⚠️ Boş mesaj")
            return
        }
        
        messageText = ""
        isTextFieldFocused = false
        authError = nil
        
        Task {
            await messageViewModel.sendMessage(chat: chat, sender: currentUser, text: text)
        }
    }
}

// MARK: - Message Bubble (Link Desteği ile)
struct MessageBubbleView: View {
    @EnvironmentObject var themeViewModel: ThemeViewModel
    
    let message: Message
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                // Link destekli metin
                LinkableTextView(text: message.text, isCurrentUser: isCurrentUser)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Group {
                            if isCurrentUser {
                                LinearGradient(
                                    colors: [
                                        themeViewModel.currentTheme.primaryColor,
                                        themeViewModel.currentTheme.secondaryColor
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            } else {
                                themeViewModel.currentTheme.cardBackgroundColor
                            }
                        }
                    )
                    .cornerRadius(18)
                
                Text(timeString(from: message.timestamp))
                    .font(.caption2)
                    .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
                    .padding(.horizontal, 4)
            }
            
            if !isCurrentUser {
                Spacer(minLength: 60)
            }
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
}
