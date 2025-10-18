//
//  UsersViewModel.swift
//  UlakMessage
//
//  Konum: ViewModels/UsersViewModel.swift
//

import SwiftUI
import Combine

@MainActor
class UsersViewModel: ObservableObject {
    @Published var searchResults: [User] = []
    @Published var isSearching = false
    @Published var errorMessage: String?
    
    private let databaseService = DatabaseService.shared
    
    // Kullanıcı ara
    func searchUsers(query: String, currentUserId: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        errorMessage = nil
        
        do {
            searchResults = try await databaseService.searchUsersByUsername(query, currentUserId: currentUserId)
        } catch {
            errorMessage = "Arama sırasında bir hata oluştu: \(error.localizedDescription)"
        }
        
        isSearching = false
    }
    
    func clearSearch() {
        searchResults = []
        errorMessage = nil
    }
}
