//
//  RegisterView.swift
//  UlakMessage
//
//  Konum: Views/Authentication/RegisterView.swift
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeViewModel: ThemeViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var username = ""
    @State private var displayName = ""
    @State private var localError: String?
    @State private var isCheckingUsername = false
    @State private var usernameAvailable: Bool?
    
    var body: some View {
        NavigationView {
            ZStack {
                themeViewModel.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Logo ve başlık
                        VStack(spacing: 15) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 60))
                                .foregroundColor(themeViewModel.currentTheme.primaryColor)
                            
                            Text("Hesap Oluştur")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(themeViewModel.currentTheme.textColor)
                            
                            Text("Yeni bir hesap oluşturun")
                                .font(.subheadline)
                                .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
                        }
                        .padding(.top, 40)
                        
                        // Form alanları
                        VStack(spacing: 20) {
                            // Kullanıcı adı (Eşsiz)
                            VStack(alignment: .leading, spacing: 8) {
                                CustomTextField(
                                    title: "Kullanıcı Adı",
                                    placeholder: "ornekkullanici",
                                    text: $username,
                                    icon: "at"
                                )
                                .onChange(of: username) { oldValue, newValue in
                                    usernameAvailable = nil
                                    if !newValue.isEmpty {
                                        checkUsernameDebounced(newValue)
                                    }
                                }
                                
                                if isCheckingUsername {
                                    HStack(spacing: 5) {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                        Text("Kontrol ediliyor...")
                                            .font(.caption)
                                            .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
                                    }
                                } else if let available = usernameAvailable {
                                    HStack(spacing: 5) {
                                        Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        Text(available ? "Kullanılabilir" : "Bu kullanıcı adı alınmış")
                                            .font(.caption)
                                    }
                                    .foregroundColor(available ? themeViewModel.currentTheme.successColor : themeViewModel.currentTheme.errorColor)
                                }
                            }
                            
                            CustomTextField(
                                title: "İsim (Opsiyonel)",
                                placeholder: "Adınız Soyadınız",
                                text: $displayName,
                                icon: "person"
                            )
                            
                            CustomTextField(
                                title: "E-posta",
                                placeholder: "ornek@email.com",
                                text: $email,
                                keyboardType: .emailAddress,
                                icon: "envelope"
                            )
                            
                            CustomTextField(
                                title: "Şifre",
                                placeholder: "En az 6 karakter",
                                text: $password,
                                isSecure: true,
                                icon: "lock"
                            )
                            
                            CustomTextField(
                                title: "Şifre Tekrar",
                                placeholder: "Şifrenizi tekrar girin",
                                text: $confirmPassword,
                                isSecure: true,
                                icon: "lock.fill"
                            )
                        }
                        .padding(.horizontal, 30)
                        
                        // Hata mesajı
                        if let errorMessage = localError ?? authViewModel.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(themeViewModel.currentTheme.errorColor)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                        
                        // Kayıt ol butonu
                        Button(action: {
                            validateAndRegister()
                        }) {
                            HStack {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Kayıt Ol")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
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
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(authViewModel.isLoading || !isFormValid)
                        .opacity((authViewModel.isLoading || !isFormValid) ? 0.6 : 1.0)
                        .padding(.horizontal, 30)
                        
                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Geri")
                        }
                        .foregroundColor(themeViewModel.currentTheme.primaryColor)
                    }
                }
            }
        }
        .onChange(of: authViewModel.currentUser) { oldValue, newValue in
            if newValue != nil {
                dismiss()
            }
        }
    }
    
    private var isFormValid: Bool {
        !username.isEmpty && !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty && usernameAvailable == true
    }
    
    private func checkUsernameDebounced(_ username: String) {
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 saniye bekle
            await checkUsername(username)
        }
    }
    
    private func checkUsername(_ username: String) async {
        guard !username.isEmpty else { return }
        
        isCheckingUsername = true
        
        do {
            usernameAvailable = try await AuthService.shared.isUsernameAvailable(username)
        } catch {
            usernameAvailable = nil
        }
        
        isCheckingUsername = false
    }
    
    private func validateAndRegister() {
        localError = nil
        
        // Kullanıcı adı kontrolü
        guard !username.isEmpty, username.count >= 3 else {
            localError = "Kullanıcı adı en az 3 karakter olmalıdır."
            return
        }
        
        guard usernameAvailable == true else {
            localError = "Bu kullanıcı adı kullanılamaz."
            return
        }
        
        // Şifre kontrolü
        guard password == confirmPassword else {
            localError = "Şifreler eşleşmiyor."
            return
        }
        
        guard password.count >= 6 else {
            localError = "Şifre en az 6 karakter olmalıdır."
            return
        }
        
        // E-posta kontrolü
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: email) else {
            localError = "Geçerli bir e-posta adresi girin."
            return
        }
        
        Task {
            await authViewModel.signUp(
                email: email,
                password: password,
                username: username,
                displayName: displayName.isEmpty ? nil : displayName
            )
        }
    }
}
