//
//  AddUserView.swift
//  UlakMessage
//
//  Konum: Views/Chat/AddUserView.swift
//

import SwiftUI

struct AddUserView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeViewModel: ThemeViewModel
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var usersViewModel = UsersViewModel()
    @StateObject private var friendsViewModel = FriendsViewModel()
    @StateObject private var chatViewModel = ChatViewModel()
    
    @State private var searchText = ""
    @State private var selectedChatWrapper: ChatWithUser?
    
    var body: some View {
        NavigationView {
            ZStack {
                themeViewModel.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Arama barı
                    searchBar
                    
                    // Sonuçlar
                    contentView
                }
            }
            .navigationTitle("Kişi Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(themeViewModel.currentTheme.primaryColor)
                }
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
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
            
            TextField("Kullanıcı adı ara...", text: $searchText)
                .foregroundColor(themeViewModel.currentTheme.textColor)
                .autocapitalization(.none)
                .onChange(of: searchText) { oldValue, newValue in
                    Task {
                        if let currentUserId = authViewModel.currentUser?.id {
                            await usersViewModel.searchUsers(query: newValue, currentUserId: currentUserId)
                        }
                    }
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    usersViewModel.clearSearch()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
                }
            }
        }
        .padding()
        .background(themeViewModel.currentTheme.cardBackgroundColor)
        .cornerRadius(12)
        .padding()
    }
    
    // MARK: - Content View
    @ViewBuilder
    private var contentView: some View {
        if usersViewModel.isSearching {
            Spacer()
            ProgressView()
                .tint(themeViewModel.currentTheme.primaryColor)
            Spacer()
        } else if searchText.isEmpty {
            emptySearchView
        } else if usersViewModel.searchResults.isEmpty {
            noResultsView
        } else {
            searchResultsView
        }
    }
    
    private var emptySearchView: some View {
        VStack(spacing: 15) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
            
            Text("Kullanıcı Ara")
                .font(.headline)
                .foregroundColor(themeViewModel.currentTheme.textColor)
            
            Text("Kullanıcı adı ile arama yapın")
                .font(.subheadline)
                .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
            Spacer()
        }
    }
    
    private var noResultsView: some View {
        VStack(spacing: 15) {
            Spacer()
            Image(systemName: "person.crop.circle.badge.xmark")
                .font(.system(size: 50))
                .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
            
            Text("Kullanıcı Bulunamadı")
                .font(.headline)
                .foregroundColor(themeViewModel.currentTheme.textColor)
            
            Text("'\(searchText)' için sonuç bulunamadı")
                .font(.subheadline)
                .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
            Spacer()
        }
    }
    
    private var searchResultsView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(usersViewModel.searchResults) { user in
                    UserSearchRowView(
                        user: user,
                        onMessageTap: {
                            openChat(with: user)
                        }
                    )
                    
                    if user.id != usersViewModel.searchResults.last?.id {
                        Divider()
                            .background(themeViewModel.currentTheme.borderColor)
                            .padding(.leading, 85)
                    }
                }
            }
        }
    }
    
    private func openChat(with user: User) {
        guard let currentUser = authViewModel.currentUser else { return }
        
        Task {
            if let chat = await chatViewModel.getOrCreateChat(currentUser: currentUser, otherUser: user) {
                let wrapper = ChatWithUser(
                    chat: chat,
                    otherUserId: user.id,
                    otherUsername: user.username,
                    otherDisplayName: user.displayName
                )
                selectedChatWrapper = wrapper
            }
        }
    }
}

// MARK: - Kullanıcı Arama Satırı
struct UserSearchRowView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeViewModel: ThemeViewModel
    @StateObject private var friendsViewModel = FriendsViewModel()
    
    let user: User
    let onMessageTap: () -> Void
    
    @State private var isFriend = false
    @State private var requestSent = false
    @State private var isLoading = true
    @State private var showSuccess = false
    
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
                    Text(String(user.displayName?.prefix(1) ?? user.username.prefix(1)).uppercased())
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName ?? user.username)
                    .font(.headline)
                    .foregroundColor(themeViewModel.currentTheme.textColor)
                
                Text("@\(user.username)")
                    .font(.subheadline)
                    .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
                
                // Privacy badge
                HStack(spacing: 4) {
                    Image(systemName: user.privacySettings.whoCanMessage == .everyone ? "globe" : "lock.fill")
                        .font(.caption2)
                    Text(user.privacySettings.whoCanMessage.rawValue)
                        .font(.caption)
                }
                .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
            }
            
            Spacer()
            
            // Aksiyon butonu
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                actionButtons
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .task {
            await checkStatus()
        }
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        if isFriend {
            // Zaten arkadaş - Sadece Mesaj
            Button(action: onMessageTap) {
                HStack(spacing: 5) {
                    Image(systemName: "message.fill")
                        .font(.caption)
                    Text("Mesaj")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(themeViewModel.currentTheme.primaryColor)
                .cornerRadius(20)
            }
        } else if requestSent || showSuccess {
            // İstek gönderildi
            HStack(spacing: 5) {
                Image(systemName: "checkmark")
                    .font(.caption)
                Text("Gönderildi")
                    .font(.subheadline)
            }
            .foregroundColor(themeViewModel.currentTheme.successColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(themeViewModel.currentTheme.successColor.opacity(0.1))
            .cornerRadius(20)
        } else if user.privacySettings.whoCanMessage == .everyone {
            // Herkes mesaj gönderebilir - HEM MESAJ HEM ARKADAŞ EKLE
            HStack(spacing: 8) {
                // Mesaj butonu
                Button(action: onMessageTap) {
                    Image(systemName: "message.fill")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(themeViewModel.currentTheme.primaryColor)
                        .clipShape(Circle())
                }
                
                // Arkadaş ekle butonu
                Button(action: {
                    sendFriendRequest()
                }) {
                    Image(systemName: "person.badge.plus")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
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
                        .clipShape(Circle())
                }
            }
        } else {
            // Sadece arkadaşlar - SADECE ARKADAŞ EKLE
            Button(action: {
                sendFriendRequest()
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "person.badge.plus")
                        .font(.caption)
                    Text("Arkadaş Ekle")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
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
                .cornerRadius(20)
            }
        }
    }
    
    private func checkStatus() async {
        guard let currentUserId = authViewModel.currentUser?.id else { return }
        
        isLoading = true
        
        // Arkadaş mı kontrol et
        isFriend = await friendsViewModel.isFriend(userId: currentUserId, friendId: user.id)
        
        // İstek gönderilmiş mi kontrol et
        if !isFriend {
            requestSent = await friendsViewModel.hasSentFriendRequest(from: currentUserId, to: user.id)
        }
        
        isLoading = false
    }
    
    private func sendFriendRequest() {
        guard let currentUser = authViewModel.currentUser else { return }
        
        Task {
            await friendsViewModel.sendFriendRequest(from: currentUser, to: user)
            
            if friendsViewModel.errorMessage == nil {
                withAnimation {
                    showSuccess = true
                }
            }
        }
    }
}
