//
//  MainTabView.swift
//  UlakMessage
//
//  Konum: Views/Main/MainTabView.swift
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeViewModel: ThemeViewModel
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Sohbetler
            ChatsView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "message.fill" : "message")
                    Text("Sohbetler")
                }
                .tag(0)
            
            // Ayarlar
            SettingsView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "gearshape.fill" : "gearshape")
                    Text("Ayarlar")
                }
                .tag(1)
        }
        .accentColor(themeViewModel.currentTheme.primaryColor)
    }
}
