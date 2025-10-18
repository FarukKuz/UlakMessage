//
//  UlakMessageApp.swift
//  UlakMessage
//
//  Root klasörde olmalı
//

import SwiftUI
import FirebaseCore
import FirebaseDatabase

@main
struct UlakMessageApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var themeViewModel = ThemeViewModel()
    
    init() {
        FirebaseApp.configure()
        
        // Firebase Realtime Database persistence ayarları
        Database.database().isPersistenceEnabled = true
        
        // Keep synced - Aktif dinleyici ekle
        let ref = Database.database().reference()
        ref.child("users").keepSynced(true)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(themeViewModel)
                .preferredColorScheme(themeViewModel.currentTheme.colorScheme)
        }
    }
}

// ContentView - İlk açılış ekranı
struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.isLoading {
                LoadingView()
            } else if authViewModel.currentUser != nil {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}

// Loading ekranı
struct LoadingView: View {
    @EnvironmentObject var themeViewModel: ThemeViewModel
    
    var body: some View {
        ZStack {
            themeViewModel.currentTheme.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "message.fill")
                    .font(.system(size: 60))
                    .foregroundColor(themeViewModel.currentTheme.primaryColor)
                
                Text("Ulak Message")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(themeViewModel.currentTheme.textColor)
                
                ProgressView()
                    .tint(themeViewModel.currentTheme.primaryColor)
            }
        }
    }
}
