//
//  ChatDetailView.swift
//  UlakMessage
//

import SwiftUI
import FirebaseAuth
import PhotosUI
import UniformTypeIdentifiers

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
    @State private var showUserProfile = false
    @State private var showMediaPicker = false // 📎 Medya seçici sheet
    
    // Picker state'leri
    @State private var showPhotoPicker = false
    @State private var showVideoPicker = false
    @State private var showDocumentPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedVideoItem: PhotosPickerItem?
    
    // Kullanıcı durumu (realtime)
    @State private var otherUserOnlineStatus: Bool = false
    @State private var otherUserLastSeen: Date?
    
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
                        if messageViewModel.isLoading {
                            ProgressView()
                                .padding()
                        } else if messageViewModel.messages.isEmpty {
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
                .onChange(of: messageViewModel.shouldScrollToBottom) { oldValue, newValue in
                    if newValue, let lastMessage = messageViewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                        messageViewModel.shouldScrollToBottom = false
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
        .sheet(isPresented: $showUserProfile) {
            UserProfileView(
                userId: otherUserId,
                username: otherUsername,
                displayName: otherDisplayName,
                isOnline: otherUserOnlineStatus,
                lastSeen: otherUserLastSeen
            )
        }
        .sheet(isPresented: $showMediaPicker) {
            MediaPickerSheet { type in
                handleMediaTypeSelection(type)
            }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .photosPicker(isPresented: $showVideoPicker, selection: $selectedVideoItem, matching: .videos)
        .fileImporter(isPresented: $showDocumentPicker, allowedContentTypes: [.pdf, .text, .plainText, .spreadsheet, .presentation], allowsMultipleSelection: false) { result in
            handleDocumentSelection(result)
        }
        .onChange(of: selectedPhotoItem) { _, newValue in
            if let item = newValue {
                handlePhotoSelection(item)
            }
        }
        .onChange(of: selectedVideoItem) { _, newValue in
            if let item = newValue {
                handleVideoSelection(item)
            }
        }
        .onAppear {
            checkAuthStatus()
            messageViewModel.startObserving(chatId: chat.id)
            startObservingOtherUser()
        }
        .onDisappear {
            messageViewModel.stopObserving()
            stopObservingOtherUser()
        }
    }
    
    // MARK: - 👁️ KULLANICI DURUMUNU DİNLE
    private func startObservingOtherUser() {
        UserService.shared.observeUser(userId: otherUserId) { user in
            if let user = user {
                otherUserOnlineStatus = user.isOnline
                otherUserLastSeen = user.lastSeen
            }
        }
    }
    
    private func stopObservingOtherUser() {
        UserService.shared.removeUserObserver(userId: otherUserId)
    }
    
    // Auth durumunu kontrol et
    private func checkAuthStatus() {
        if Auth.auth().currentUser == nil {
            authError = "Oturum bulunamadı. Lütfen çıkış yapıp tekrar giriş yapın."
        } else if authViewModel.currentUser == nil {
            authError = "Kullanıcı bilgisi bulunamadı."
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
    
    // MARK: - Header (Online Durumu ile)
    private var headerView: some View {
        HStack(spacing: 12) {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(themeViewModel.currentTheme.primaryColor)
            }
            
            // Tıklanabilir profil alanı
            Button(action: {
                showUserProfile = true
            }) {
                HStack(spacing: 12) {
                    // Avatar + Online indicator
                    ZStack(alignment: .bottomTrailing) {
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
                        
                        // Online durumu
                        if otherUserOnlineStatus {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 12, height: 12)
                                .overlay(
                                    Circle()
                                        .stroke(themeViewModel.currentTheme.backgroundColor, lineWidth: 2)
                                )
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(otherDisplayName ?? otherUsername)
                            .font(.headline)
                            .foregroundColor(themeViewModel.currentTheme.textColor)
                        
                        // Online/Offline durumu
                        Text(userStatusText)
                            .font(.caption)
                            .foregroundColor(otherUserOnlineStatus ? .green : themeViewModel.currentTheme.secondaryTextColor)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
        .padding()
        .background(themeViewModel.currentTheme.backgroundColor)
    }
    
    private var userStatusText: String {
        if otherUserOnlineStatus {
            return "Çevrimiçi"
        } else if let lastSeen = otherUserLastSeen {
            return "Son görülme: \(formatLastSeen(lastSeen))"
        } else {
            return "@\(otherUsername)"
        }
    }
    
    private func formatLastSeen(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
            return "bugün \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "HH:mm"
            return "dün \(formatter.string(from: date))"
        } else {
            formatter.dateFormat = "dd.MM.yyyy HH:mm"
            return formatter.string(from: date)
        }
    }
    
    // MARK: - Message Input (Gelişmiş Medya Desteği)
    private var messageInputView: some View {
        HStack(spacing: 12) {
            // 📎 Medya butonu
            Button(action: {
                showMediaPicker = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(themeViewModel.currentTheme.primaryColor)
            }
            
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
        guard Auth.auth().currentUser != nil,
              let currentUser = authViewModel.currentUser else {
            authError = "Oturum bulunamadı."
            return
        }
        
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        messageText = ""
        isTextFieldFocused = false
        authError = nil
        
        Task {
            await messageViewModel.sendMessage(chat: chat, sender: currentUser, text: text)
        }
    }
    
    // MARK: - Medya İşleme
    private func handleMediaTypeSelection(_ type: MediaPickerType) {
        switch type {
        case .photo:
            showPhotoPicker = true
        case .video:
            showVideoPicker = true
        case .document:
            showDocumentPicker = true
        case .audio:
            // Ses kaydı için ayrı bir view açılabilir
            print("🎤 Ses kaydı özelliği yakında...")
        case .location:
            // Konum paylaşımı için CoreLocation kullanılabilir
            print("📍 Konum paylaşımı özelliği yakında...")
        }
    }
    
    private func handlePhotoSelection(_ item: PhotosPickerItem) {
        Task {
            print("📸 Fotoğraf seçildi - Firebase Storage'a yüklenecek")
            // TODO: Firebase Storage'a yükle
        }
    }
    
    private func handleVideoSelection(_ item: PhotosPickerItem) {
        Task {
            print("🎥 Video seçildi - Firebase Storage'a yüklenecek")
            // TODO: Firebase Storage'a yükle
        }
    }
    
    private func handleDocumentSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                print("📄 Belge seçildi: \(url.lastPathComponent)")
                // TODO: Firebase Storage'a yükle
            }
        case .failure(let error):
            print("❌ Belge seçim hatası: \(error)")
        }
    }
}

// MARK: - Message Bubble (Medya Desteği ile)
// MARK: - Message Bubble (Link Desteği ile) - DÜZELTİLMİŞ
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
                // ✅ DÜZELTME: Background'u LinkableTextView'ın ALT KATMANINA taşı
                ZStack {
                    // Background
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
                    .cornerRadius(18)
                    
                    // Link destekli metin - ÜST KATMANDA
                    LinkableTextView(text: message.text, isCurrentUser: isCurrentUser)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
                .fixedSize(horizontal: false, vertical: true)
                
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
