//
//  FriendsViewModel.swift
//  UlakMessage
//
//  Konum: ViewModels/FriendsViewModel.swift
//

import SwiftUI
import Combine

@MainActor
class FriendsViewModel: ObservableObject {
    @Published var friends: [User] = []
    @Published var incomingRequests: [FriendRequest] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let friendService = FriendService.shared
    
    // Arkadaşlık isteği gönder
    func sendFriendRequest(from: User, to: User) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await friendService.sendFriendRequest(from: from, to: to)
        } catch {
            errorMessage = "İstek gönderilemedi: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // Arkadaşlık isteğini kabul et
    func acceptFriendRequest(_ request: FriendRequest) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await friendService.acceptFriendRequest(request)
            await fetchIncomingRequests(for: request.toUserId)
            await fetchFriends(for: request.toUserId)
        } catch {
            errorMessage = "İstek kabul edilemedi: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // Arkadaşlık isteğini reddet
    func rejectFriendRequest(_ request: FriendRequest) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await friendService.rejectFriendRequest(request)
            await fetchIncomingRequests(for: request.toUserId)
        } catch {
            errorMessage = "İstek reddedilemedi: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // Arkadaşı kaldır (YENİ)
    func removeFriend(userId: String, friendId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await friendService.removeFriend(userId: userId, friendId: friendId)
        } catch {
            errorMessage = "Arkadaş kaldırılamadı: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // Gelen istekleri getir
    func fetchIncomingRequests(for userId: String) async {
        do {
            incomingRequests = try await friendService.fetchIncomingFriendRequests(for: userId)
        } catch {
            errorMessage = "İstekler getirilemedi: \(error.localizedDescription)"
        }
    }
    
    // Arkadaşları getir
    func fetchFriends(for userId: String) async {
        isLoading = true
        do {
            friends = try await friendService.fetchFriends(for: userId)
        } catch {
            errorMessage = "Arkadaşlar getirilemedi: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    // Arkadaş mı kontrol et
    func isFriend(userId: String, friendId: String) async -> Bool {
        do {
            return try await friendService.isFriend(userId: userId, friendId: friendId)
        } catch {
            return false
        }
    }
    
    // İstek gönderilmiş mi kontrol et
    func hasSentFriendRequest(from userId: String, to friendId: String) async -> Bool {
        do {
            return try await friendService.hasSentFriendRequest(from: userId, to: friendId)
        } catch {
            return false
        }
    }
}
