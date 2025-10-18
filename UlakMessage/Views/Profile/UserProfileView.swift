//
//  UserProfileView.swift
//  UlakMessage
//
//  Konum: Views/Profile/UserProfileView.swift
//

import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var themeViewModel: ThemeViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    let userId: String
    let username: String
    let displayName: String?
    let isOnline: Bool
    let lastSeen: Date?
    
    @State private var user: User?
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient arkaplan
                LinearGradient(
                    colors: [
                        themeViewModel.currentTheme.primaryColor.opacity(0.1),
                        themeViewModel.currentTheme.backgroundColor
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(themeViewModel.currentTheme.primaryColor)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 30) {
                            // Kimlik Kartı
                            identityCardView
                                .padding(.top, 20)
                            
                            // Ek Bilgiler
                            additionalInfoView
                                .padding(.horizontal)
                            
                            Spacer(minLength: 40)
                        }
                    }
                }
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
                    }
                }
            }
            .task {
                await fetchUserData()
            }
        }
    }
    
    // MARK: - 🆔 KİMLİK KARTI
    private var identityCardView: some View {
        ZStack {
            // Kart arkaplanı
            RoundedRectangle(cornerRadius: 20)
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
                .shadow(color: themeViewModel.currentTheme.primaryColor.opacity(0.3), radius: 20, x: 0, y: 10)
            
            VStack(spacing: 0) {
                // Üst bölüm - Logo/Başlık alanı
                HStack {
                    Image(systemName: "person.text.rectangle")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text("ULAK MESSAGE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.8))
                        .tracking(2)
                }
                .padding()
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                // Ana içerik - Profil bilgileri
                HStack(alignment: .top, spacing: 20) {
                    // Sol taraf - Profil fotoğrafı
                    VStack(spacing: 12) {
                        ZStack(alignment: .bottomTrailing) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Text(String(displayName?.prefix(1) ?? username.prefix(1)).uppercased())
                                        .font(.system(size: 40))
                                        .fontWeight(.bold)
                                        .foregroundColor(themeViewModel.currentTheme.primaryColor)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.5), lineWidth: 3)
                                )
                            
                            // Online durumu
                            Circle()
                                .fill(isOnline ? Color.green : Color.gray)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 3)
                                )
                        }
                        
                        // Online/Offline durumu text
                        HStack(spacing: 4) {
                            Circle()
                                .fill(isOnline ? Color.green : Color.gray)
                                .frame(width: 8, height: 8)
                            
                            Text(isOnline ? "Çevrimiçi" : "Çevrimdışı")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                    }
                    .padding(.top, 20)
                    
                    // Sağ taraf - Kullanıcı bilgileri
                    VStack(alignment: .leading, spacing: 16) {
                        // İsim
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AD SOYAD")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white.opacity(0.7))
                                .tracking(1)
                            
                            Text(displayName ?? username)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                        
                        // Kullanıcı adı
                        VStack(alignment: .leading, spacing: 4) {
                            Text("KULLANICI ADI")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white.opacity(0.7))
                                .tracking(1)
                            
                            HStack(spacing: 4) {
                                Text("@")
                                    .foregroundColor(.white.opacity(0.8))
                                Text(username)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            .font(.body)
                        }
                        
                        // Son görülme
                        VStack(alignment: .leading, spacing: 4) {
                            Text("SON GÖRÜLME")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white.opacity(0.7))
                                .tracking(1)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption)
                                Text(lastSeenText())
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .padding(.top, 20)
                    .padding(.trailing, 8)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 25)
            }
        }
        .frame(height: 280)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Ek Bilgiler
    private var additionalInfoView: some View {
        VStack(spacing: 16) {
            // User ID
            InfoCard(
                icon: "number.circle.fill",
                title: "Kullanıcı ID",
                value: userId,
                color: themeViewModel.currentTheme.primaryColor
            )
            
            // Email (eğer varsa)
            if let user = user {
                InfoCard(
                    icon: "envelope.circle.fill",
                    title: "E-posta",
                    value: user.email,
                    color: themeViewModel.currentTheme.secondaryColor
                )
            }
        }
    }
    
    // MARK: - Helper Functions
    private func lastSeenText() -> String {
        if isOnline {
            return "Şu anda aktif"
        }
        
        guard let lastSeen = lastSeen else {
            return "Bilinmiyor"
        }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        
        let calendar = Calendar.current
        if calendar.isDateInToday(lastSeen) {
            formatter.dateFormat = "HH:mm"
            return "Bugün \(formatter.string(from: lastSeen))"
        } else if calendar.isDateInYesterday(lastSeen) {
            formatter.dateFormat = "HH:mm"
            return "Dün \(formatter.string(from: lastSeen))"
        } else {
            formatter.dateFormat = "dd.MM.yyyy HH:mm"
            return formatter.string(from: lastSeen)
        }
    }
    
    private func fetchUserData() async {
        isLoading = true
        
        do {
            // Gerçek veriyi çek
            user = try await UserService.shared.getUser(userId: userId)
        } catch {
            print("❌ Kullanıcı bilgisi alınamadı: \(error.localizedDescription)")
            
            // Hata durumunda minimal mock data
            user = User(
                id: userId,
                email: "bilinmiyor",
                username: username,
                displayName: displayName,
                createdAt: Date(),
                lastSeen: lastSeen,
                isOnline: isOnline
            )
        }
        
        isLoading = false
    }
}

// MARK: - Info Card Component
struct InfoCard: View {
    @EnvironmentObject var themeViewModel: ThemeViewModel
    
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // İkon
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
            }
            
            // Bilgi
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeViewModel.currentTheme.textColor)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding()
        .background(themeViewModel.currentTheme.cardBackgroundColor)
        .cornerRadius(15)
    }
}

// MARK: - Preview
#Preview {
    UserProfileView(
        userId: "123456",
        username: "faruk_kuz",
        displayName: "Faruk Kuzucu",
        isOnline: true,
        lastSeen: Date().addingTimeInterval(-3600)
    )
    .environmentObject(ThemeViewModel())
    .environmentObject(AuthViewModel())
}
