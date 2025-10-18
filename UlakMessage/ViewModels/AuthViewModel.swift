//
//  AuthViewModel.swift
//  UlakMessage
//
//  Konum: ViewModels/AuthViewModel.swift
//

import SwiftUI
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading = true
    @Published var errorMessage: String?
    
    private let authService = AuthService.shared
    private let databaseService = DatabaseService.shared
    
    init() {
        Task {
            await checkAuthStatus()
        }
    }
    
    // App açıldığında
    func checkAuthStatus() async {
        isLoading = true
        do {
            currentUser = try await authService.checkAuthStatus()
            
            // Eğer kullanıcı varsa presence tracking başlat
            if let userId = currentUser?.id {
                UserService.shared.startPresenceTracking(userId: userId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    // Kayıt ol
    func signUp(email: String, password: String, username: String, displayName: String?) async {
        isLoading = true
        errorMessage = nil
        
        do {
            currentUser = try await authService.signUp(email: email, password: password, username: username, displayName: displayName)
        } catch {
            errorMessage = getErrorMessage(from: error)
        }
        
        isLoading = false
    }
    
    // Giriş yap
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            currentUser = try await authService.signIn(email: email, password: password)
        } catch {
            errorMessage = getErrorMessage(from: error)
        }
        
        isLoading = false
    }
    
    // Çıkış yapılınca
    func signOut() {
        if let userId = currentUser?.id {
            UserService.shared.stopPresenceTracking(userId: userId)
        }
        
        do {
            try authService.signOut()
            currentUser = nil
        } catch {
            errorMessage = getErrorMessage(from: error)
        }
    }
    
    // Privacy settings güncelle
    func updatePrivacySettings(_ settings: PrivacySettings) async {
        guard let userId = currentUser?.id else { return }
        
        do {
            try await databaseService.updatePrivacySettings(uid: userId, settings: settings)
            currentUser?.privacySettings = settings
        } catch {
            errorMessage = "Ayarlar güncellenemedi: \(error.localizedDescription)"
        }
    }
    
    // Hata mesajlarını Türkçeleştir
    private func getErrorMessage(from error: Error) -> String {
        let nsError = error as NSError
        
        switch nsError.code {
        case -2:
            return nsError.localizedDescription
        case 17007:
            return "Bu e-posta adresi zaten kullanımda."
        case 17008:
            return "E-posta adresi geçersiz."
        case 17009:
            return "Şifre yanlış."
        case 17011:
            return "Bu e-posta adresine ait kullanıcı bulunamadı."
        case 17026:
            return "Şifre en az 6 karakter olmalıdır."
        default:
            return error.localizedDescription
        }
    }
}
