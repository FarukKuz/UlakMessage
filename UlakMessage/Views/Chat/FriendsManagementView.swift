//
//  FriendsManagementView.swift
//  UlakMessage
//
//  Konum: Views/Chat/FriendsManagementView.swift
//

import SwiftUI

struct FriendsManagementView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeViewModel: ThemeViewModel
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var friendsViewModel = FriendsViewModel()
    @StateObject private var chatViewModel = ChatViewModel()
    
    @State private var selectedTab = 0
    @State private var showDeleteConfirmation = false
    @State private var friendToDelete: User?
    @State private var selectedChatWrapper: ChatWithUser?
    @State private var isLoadingChat = false
    
    var body: some View {
        ZStack {
            themeViewModel.currentTheme.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                headerView
                
                // Segmented Control
                Picker("", selection: $selectedTab) {
                    HStack {
                        Image(systemName: "person.2.fill")
                        Text("Arkadaşlar")
                    }
                    .tag(0)
                    
                    HStack {
                        Image(systemName: "envelope.badge.fill")
                        Text("İstekler")
                        if !friendsViewModel.incomingRequests.isEmpty {
                            Text("(\(friendsViewModel.incomingRequests.count))")
                        }
                    }
                    .tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content
                if selectedTab == 0 {
                    friendsListView
                } else {
                    friendRequestsListView
                }
            }
            
            // Loading overlay
            if isLoadingChat {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("Chat açılıyor...")
                        .foregroundColor(.white)
                        .font(.headline)
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            if let userId = authViewModel.currentUser?.id {
                await friendsViewModel.fetchFriends(for: userId)
                await friendsViewModel.fetchIncomingRequests(for: userId)
            }
        }
        .alert("Arkadaşı Kaldır", isPresented: $showDeleteConfirmation) {
            Button("İptal", role: .cancel) {}
            Button("Kaldır", role: .destructive) {
                if let friend = friendToDelete {
                    removeFriend(friend)
                }
            }
        } message: {
            if let friend = friendToDelete {
                Text("\(friend.displayName ?? friend.username) arkadaş listenizden kaldırılacak. Emin misiniz?")
            }
        }
        .fullScreenCover(item: $selectedChatWrapper) { wrapper in
            ChatDetailView(
                chat: wrapper.chat,
                otherUserId: wrapper.otherUserId,
                otherUsername: wrapper.otherUsername,
                otherDisplayName: wrapper.otherDisplayName
            )
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.left")
                    Text("Geri")
                }
                .foregroundColor(themeViewModel.currentTheme.primaryColor)
            }
            
            Spacer()
            
            Text("Arkadaşlarım")
                .font(.headline)
                .foregroundColor(themeViewModel.currentTheme.textColor)
            
            Spacer()
            
            // Boş alan (simetri için)
            Text("Geri")
                .opacity(0)
        }
        .padding()
        .background(themeViewModel.currentTheme.backgroundColor)
    }
    
    // MARK: - Friends List View
    private var friendsListView: some View {
        Group {
            if friendsViewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                        .tint(themeViewModel.currentTheme.primaryColor)
                    Spacer()
                }
            } else if friendsViewModel.friends.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 60))
                        .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
                    
                    Text("Henüz arkadaşınız yok")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(themeViewModel.currentTheme.textColor)
                    
                    Text("Arkadaş ekleyerek mesajlaşmaya başlayın")
                        .font(.subheadline)
                        .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(friendsViewModel.friends) { friend in
                            FriendManagementRowView(
                                friend: friend,
                                onMessage: {
                                    openChat(with: friend)
                                },
                                onDelete: {
                                    friendToDelete = friend
                                    showDeleteConfirmation = true
                                }
                            )
                            
                            if friend.id != friendsViewModel.friends.last?.id {
                                Divider()
                                    .background(themeViewModel.currentTheme.borderColor)
                                    .padding(.leading, 85)
                            }
                        }
                    }
                }
                .refreshable {
                    if let userId = authViewModel.currentUser?.id {
                        await friendsViewModel.fetchFriends(for: userId)
                    }
                }
            }
        }
    }
    
    // MARK: - Friend Requests List View
    private var friendRequestsListView: some View {
        Group {
            if friendsViewModel.incomingRequests.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "tray")
                        .font(.system(size: 60))
                        .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
                    
                    Text("Arkadaşlık İsteği Yok")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(themeViewModel.currentTheme.textColor)
                    
                    Text("Henüz arkadaşlık isteği almadınız")
                        .font(.subheadline)
                        .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(friendsViewModel.incomingRequests) { request in
                            FriendRequestRowView(request: request)
                            
                            if request.id != friendsViewModel.incomingRequests.last?.id {
                                Divider()
                                    .background(themeViewModel.currentTheme.borderColor)
                                    .padding(.leading, 85)
                            }
                        }
                    }
                }
                .refreshable {
                    if let userId = authViewModel.currentUser?.id {
                        await friendsViewModel.fetchIncomingRequests(for: userId)
                    }
                }
            }
        }
    }
    
    // MARK: - Open Chat
    private func openChat(with friend: User) {
        guard let currentUser = authViewModel.currentUser else {
            print("❌ Current user yok")
            return
        }
        
        print("💬 Chat açılıyor:")
        print("   - Current User: \(currentUser.username) (\(currentUser.id))")
        print("   - Friend: \(friend.username) (\(friend.id))")
        
        isLoadingChat = true
        
        Task {
            if let chat = await chatViewModel.getOrCreateChat(currentUser: currentUser, otherUser: friend) {
                print("✅ Chat hazır: \(chat.id)")
                
                let wrapper = ChatWithUser(
                    chat: chat,
                    otherUserId: friend.id,
                    otherUsername: friend.username,
                    otherDisplayName: friend.displayName
                )
                
                await MainActor.run {
                    isLoadingChat = false
                    selectedChatWrapper = wrapper
                }
            } else {
                print("❌ Chat oluşturulamadı")
                await MainActor.run {
                    isLoadingChat = false
                }
            }
        }
    }
    
    // MARK: - Remove Friend
    private func removeFriend(_ friend: User) {
        guard let currentUserId = authViewModel.currentUser?.id else { return }
        
        Task {
            await friendsViewModel.removeFriend(userId: currentUserId, friendId: friend.id)
            
            if friendsViewModel.errorMessage == nil {
                await friendsViewModel.fetchFriends(for: currentUserId)
            }
        }
    }
}

// MARK: - Friend Management Row
struct FriendManagementRowView: View {
    @EnvironmentObject var themeViewModel: ThemeViewModel
    
    let friend: User
    let onMessage: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            // Avatar
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
                    .frame(width: 55, height: 55)
                    .overlay(
                        Text(String(friend.displayName?.prefix(1) ?? friend.username.prefix(1)).uppercased())
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    )
                
                // Online indicator
                if friend.isOnline {
                    Circle()
                        .fill(themeViewModel.currentTheme.successColor)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle()
                                .stroke(themeViewModel.currentTheme.backgroundColor, lineWidth: 2)
                        )
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.displayName ?? friend.username)
                    .font(.headline)
                    .foregroundColor(themeViewModel.currentTheme.textColor)
                
                Text("@\(friend.username)")
                    .font(.subheadline)
                    .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
            }
            
            Spacer()
            
            // Mesaj butonu
            Button(action: onMessage) {
                Image(systemName: "message.fill")
                    .font(.title3)
                    .foregroundColor(themeViewModel.currentTheme.primaryColor)
            }
            
            // Menu butonu
            Menu {
                Button(role: .destructive, action: onDelete) {
                    Label("Arkadaşlıktan Çıkar", systemImage: "person.fill.xmark")
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.title3)
                    .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}
