//
//  FriendRequestsView.swift
//  UlakMessage
//
//  Konum: Views/Chat/FriendRequestsView.swift
//

import SwiftUI

struct FriendRequestsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeViewModel: ThemeViewModel
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var friendsViewModel = FriendsViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                themeViewModel.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                if friendsViewModel.incomingRequests.isEmpty {
                    // Boş durum
                    VStack(spacing: 20) {
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
                }
            }
            .navigationTitle("Arkadaşlık İstekleri")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(themeViewModel.currentTheme.primaryColor)
                }
            }
            .task {
                if let userId = authViewModel.currentUser?.id {
                    await friendsViewModel.fetchIncomingRequests(for: userId)
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

// Arkadaşlık isteği satırı
struct FriendRequestRowView: View {
    @EnvironmentObject var themeViewModel: ThemeViewModel
    @StateObject private var friendsViewModel = FriendsViewModel()
    
    let request: FriendRequest
    
    @State private var isProcessing = false
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
                    Text(String(request.fromDisplayName?.prefix(1) ?? request.fromUsername.prefix(1)).uppercased())
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(request.fromDisplayName ?? request.fromUsername)
                    .font(.headline)
                    .foregroundColor(themeViewModel.currentTheme.textColor)
                
                Text("@\(request.fromUsername)")
                    .font(.subheadline)
                    .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
                
                Text(timeAgo(from: request.createdAt))
                    .font(.caption)
                    .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
            }
            
            Spacer()
            
            if showSuccess {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(themeViewModel.currentTheme.successColor)
            } else if isProcessing {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                // Aksiyon butonları
                HStack(spacing: 10) {
                    // Reddet
                    Button(action: {
                        rejectRequest()
                    }) {
                        Image(systemName: "xmark")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(themeViewModel.currentTheme.errorColor)
                            .frame(width: 36, height: 36)
                            .background(themeViewModel.currentTheme.errorColor.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    // Kabul et
                    Button(action: {
                        acceptRequest()
                    }) {
                        Image(systemName: "checkmark")
                            .font(.subheadline)
                            .fontWeight(.semibold)
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
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
    
    private func acceptRequest() {
        isProcessing = true
        
        Task {
            await friendsViewModel.acceptFriendRequest(request)
            
            if friendsViewModel.errorMessage == nil {
                withAnimation {
                    showSuccess = true
                }
                
                // 1 saniye sonra kaybolsun
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            
            isProcessing = false
        }
    }
    
    private func rejectRequest() {
        isProcessing = true
        
        Task {
            await friendsViewModel.rejectFriendRequest(request)
            isProcessing = false
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        
        if seconds < 60 {
            return "Az önce"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes) dakika önce"
        } else if seconds < 86400 {
            let hours = seconds / 3600
            return "\(hours) saat önce"
        } else {
            let days = seconds / 86400
            return "\(days) gün önce"
        }
    }
}
