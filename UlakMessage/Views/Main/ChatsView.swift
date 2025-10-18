//
//  ChatsView.swift
//  UlakMessage
//
//  Konum: Views/Main/ChatsView.swift
//

import SwiftUI

struct ChatsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeViewModel: ThemeViewModel
    @StateObject private var friendsViewModel = FriendsViewModel()
    @StateObject private var chatViewModel = ChatViewModel()
    
    @State private var showAddUser = false
    @State private var showFriendsManagement = false
    @State private var selectedChatWrapper: ChatWithUser?
    
    var body: some View {
        NavigationView {
            ZStack {
                themeViewModel.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                if chatViewModel.isLoading {
                    ProgressView()
                        .tint(themeViewModel.currentTheme.primaryColor)
                } else if chatViewModel.chats.isEmpty {
                    // Boş durum
                    emptyStateView
                } else {
                    // Chat listesi
                    chatListView
                }
            }
            .navigationTitle("Ulak Message")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 15) {
                        // Arkadaş yönetimi
                        Button(action: {
                            showFriendsManagement = true
                        }) {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "person.2.fill")
                                    .font(.title3)
                                    .foregroundColor(themeViewModel.currentTheme.primaryColor)
                                
                                if !friendsViewModel.incomingRequests.isEmpty {
                                    Circle()
                                        .fill(themeViewModel.currentTheme.errorColor)
                                        .frame(width: 18, height: 18)
                                        .overlay(
                                            Text("\(friendsViewModel.incomingRequests.count)")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                        )
                                        .offset(x: 8, y: -8)
                                }
                            }
                        }
                        
                        // Kişi ekle
                        Button(action: {
                            showAddUser = true
                        }) {
                            Image(systemName: "person.badge.plus")
                                .font(.title3)
                                .foregroundColor(themeViewModel.currentTheme.primaryColor)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddUser) {
                AddUserView()
            }
            .fullScreenCover(isPresented: $showFriendsManagement) {
                FriendsManagementView()
            }
            .task {
                if let userId = authViewModel.currentUser?.id {
                    await friendsViewModel.fetchFriends(for: userId)
                    await friendsViewModel.fetchIncomingRequests(for: userId)
                    await chatViewModel.fetchChats(for: userId)
                }
            }
            .refreshable {
                if let userId = authViewModel.currentUser?.id {
                    await friendsViewModel.fetchFriends(for: userId)
                    await friendsViewModel.fetchIncomingRequests(for: userId)
                    await chatViewModel.fetchChats(for: userId)
                }
            }
        }
        .navigationViewStyle(.stack)
        .fullScreenCover(item: $selectedChatWrapper) { wrapper in
            ChatDetailView(
                chat: wrapper.chat,
                otherUserId: wrapper.otherUserId,
                otherUsername: wrapper.otherUsername,
                otherDisplayName: wrapper.otherDisplayName
            )
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "message.badge")
                .font(.system(size: 60))
                .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
            
            Text("Henüz mesajınız yok")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(themeViewModel.currentTheme.textColor)
            
            Text("Arkadaşlarınızla mesajlaşmaya başlayın")
                .font(.subheadline)
                .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
                .multilineTextAlignment(.center)
            
            Button(action: {
                showFriendsManagement = true
            }) {
                HStack {
                    Image(systemName: "person.2.fill")
                    Text("Arkadaşlarım")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [
                            themeViewModel.currentTheme.primaryColor,
                            themeViewModel.currentTheme.secondaryColor
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
            }
            .padding(.top, 10)
        }
        .padding()
    }
    
    // MARK: - Chat List
    private var chatListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(chatViewModel.chats) { chat in
                    if let wrapper = ChatWithUser(chat: chat, currentUserId: authViewModel.currentUser?.id ?? "") {
                        ChatRowView(
                            chat: chat,
                            otherUserId: wrapper.otherUserId,
                            otherUsername: wrapper.otherUsername,
                            otherDisplayName: wrapper.otherDisplayName
                        )
                        .background(themeViewModel.currentTheme.backgroundColor)
                        .onTapGesture {
                            selectedChatWrapper = wrapper
                        }
                        
                        Divider()
                            .background(themeViewModel.currentTheme.borderColor)
                            .padding(.leading, 85)
                    }
                }
            }
        }
    }
}

// MARK: - Chat Row
struct ChatRowView: View {
    @EnvironmentObject var themeViewModel: ThemeViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
    let chat: Chat
    let otherUserId: String
    let otherUsername: String
    let otherDisplayName: String?
    
    var body: some View {
        HStack(spacing: 15) {
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
                .frame(width: 55, height: 55)
                .overlay(
                    Text(String(otherDisplayName?.prefix(1) ?? otherUsername.prefix(1)).uppercased())
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(otherDisplayName ?? otherUsername)
                    .font(.headline)
                    .foregroundColor(themeViewModel.currentTheme.textColor)
                
                if let lastMessage = chat.lastMessage {
                    HStack(spacing: 4) {
                        // Kendi mesajınızsa "Siz:" prefix'i ekle
                        if chat.lastMessageSenderId == authViewModel.currentUser?.id {
                            Text("Siz:")
                                .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
                        }
                        
                        Text(lastMessage)
                            .lineLimit(1)
                            .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
                    }
                    .font(.subheadline)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let timestamp = chat.lastMessageTimestamp {
                    Text(timeAgo(from: timestamp))
                        .font(.caption)
                        .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
    
    private func timeAgo(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        
        if seconds < 60 {
            return "Şimdi"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes)dk"
        } else if seconds < 86400 {
            let hours = seconds / 3600
            return "\(hours)s"
        } else if seconds < 604800 {
            let days = seconds / 86400
            return "\(days)g"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM.yy"
            return formatter.string(from: date)
        }
    }
}
