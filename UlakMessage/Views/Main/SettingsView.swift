//
//  SettingsView.swift
//  UlakMessage
//
//  Konum: Views/Main/SettingsView.swift
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeViewModel: ThemeViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                themeViewModel.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                List {
                    // Profil Bölümü
                    profileSection
                    
                    // Güvenlik Ayarları
                    securitySection
                    
                    // Tema Bölümü
                    themeSection
                    
                    // Renk Özelleştirme Bölümü
                    colorCustomizationSection
                    
                    // Temayı Sıfırla
                    resetThemeSection
                    
                    // Çıkış Bölümü
                    logoutSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Profile Section
    private var profileSection: some View {
        Section {
            HStack(spacing: 15) {
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
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(userInitial)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(displayName)
                        .font(.headline)
                        .foregroundColor(themeViewModel.currentTheme.textColor)
                    
                    Text("@\(username)")
                        .font(.subheadline)
                        .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
                }
            }
            .padding(.vertical, 8)
        }
        .listRowBackground(themeViewModel.currentTheme.cardBackgroundColor)
    }
    
    // MARK: - Security Section
    private var securitySection: some View {
        Section(header: Text("GÜVENLİK VE GİZLİLİK")) {
            Picker("Mesaj Gönderebilir", selection: messagePrivacyBinding) {
                ForEach(PrivacySettings.MessagePrivacy.allCases, id: \.self) { privacy in
                    Text(privacy.rawValue).tag(privacy)
                }
            }
            .pickerStyle(.menu)
            .foregroundColor(themeViewModel.currentTheme.textColor)
        }
        .listRowBackground(themeViewModel.currentTheme.cardBackgroundColor)
    }
    
    // MARK: - Theme Section
    private var themeSection: some View {
        Section(header: Text("TEMA SEÇİMİ")) {
            Picker("Tema", selection: themeTypeBinding) {
                ForEach(ThemeType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
        }
        .listRowBackground(themeViewModel.currentTheme.cardBackgroundColor)
    }
    
    // MARK: - Color Customization Section
    private var colorCustomizationSection: some View {
        Section(header: Text("RENK ÖZELLEŞTİRME")) {
            ColorPickerRow(
                title: "Marka Rengi",
                colorType: .primary,
                hexColor: primaryColorBinding
            )
            
            ColorPickerRow(
                title: "İkinci Ana Renk",
                colorType: .secondary,
                hexColor: secondaryColorBinding
            )
        }
        .listRowBackground(themeViewModel.currentTheme.cardBackgroundColor)
    }
    
    // MARK: - Reset Theme Section
    private var resetThemeSection: some View {
        Section {
            Button(action: resetTheme) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Tema Renklerini Sıfırla")
                }
                .foregroundColor(themeViewModel.currentTheme.primaryColor)
            }
        }
        .listRowBackground(themeViewModel.currentTheme.cardBackgroundColor)
    }
    
    // MARK: - Logout Section
    private var logoutSection: some View {
        Section {
            Button(action: logout) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Çıkış Yap")
                }
                .foregroundColor(themeViewModel.currentTheme.errorColor)
            }
        }
        .listRowBackground(themeViewModel.currentTheme.cardBackgroundColor)
    }
    
    // MARK: - Computed Properties
    private var userInitial: String {
        if let displayName = authViewModel.currentUser?.displayName, let first = displayName.first {
            return String(first).uppercased()
        } else if let username = authViewModel.currentUser?.username, let first = username.first {
            return String(first).uppercased()
        }
        return "U"
    }
    
    private var displayName: String {
        authViewModel.currentUser?.displayName ?? authViewModel.currentUser?.username ?? "Kullanıcı"
    }
    
    private var username: String {
        authViewModel.currentUser?.username ?? ""
    }
    
    // MARK: - Bindings
    private var messagePrivacyBinding: Binding<PrivacySettings.MessagePrivacy> {
        Binding(
            get: {
                authViewModel.currentUser?.privacySettings.whoCanMessage ?? .friendsOnly
            },
            set: { newValue in
                updatePrivacySettings(newValue)
            }
        )
    }
    
    private var themeTypeBinding: Binding<ThemeType> {
        Binding(
            get: {
                themeViewModel.currentTheme.type
            },
            set: { newValue in
                themeViewModel.switchTheme(to: newValue)
            }
        )
    }
    
    private var primaryColorBinding: Binding<String> {
        Binding(
            get: {
                themeViewModel.currentTheme.primaryColorHex
            },
            set: { newValue in
                themeViewModel.updateColor(colorType: .primary, hexColor: newValue)
            }
        )
    }
    
    private var secondaryColorBinding: Binding<String> {
        Binding(
            get: {
                themeViewModel.currentTheme.secondaryColorHex
            },
            set: { newValue in
                themeViewModel.updateColor(colorType: .secondary, hexColor: newValue)
            }
        )
    }
    
    // MARK: - Actions
    private func updatePrivacySettings(_ newPrivacy: PrivacySettings.MessagePrivacy) {
        var updatedSettings = authViewModel.currentUser?.privacySettings ?? PrivacySettings()
        updatedSettings.whoCanMessage = newPrivacy
        Task {
            await authViewModel.updatePrivacySettings(updatedSettings)
        }
    }
    
    private func resetTheme() {
        themeViewModel.switchTheme(to: themeViewModel.currentTheme.type)
    }
    
    private func logout() {
        authViewModel.signOut()
    }
}
