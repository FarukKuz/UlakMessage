//
//  LoginView.swift
//  UlakMessage
//
//  Konum: Views/Authentication/LoginView.swift
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeViewModel: ThemeViewModel
    
    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false
    
    var body: some View {
        NavigationView {
            ZStack {
                themeViewModel.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Logo ve başlık
                        VStack(spacing: 15) {
                            Image(systemName: "message.fill")
                                .font(.system(size: 70))
                                .foregroundColor(themeViewModel.currentTheme.primaryColor)
                            
                            Text("Ulak Message")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(themeViewModel.currentTheme.textColor)
                            
                            Text("Hoş Geldiniz")
                                .font(.title3)
                                .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
                        }
                        .padding(.top, 60)
                        
                        // Form alanları
                        VStack(spacing: 20) {
                            CustomTextField(
                                title: "E-posta",
                                placeholder: "ornek@email.com",
                                text: $email,
                                keyboardType: .emailAddress,
                                icon: "envelope"
                            )
                            
                            CustomTextField(
                                title: "Şifre",
                                placeholder: "••••••",
                                text: $password,
                                isSecure: true,
                                icon: "lock"
                            )
                        }
                        .padding(.horizontal, 30)
                        
                        // Hata mesajı
                        if let errorMessage = authViewModel.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(themeViewModel.currentTheme.errorColor)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                        
                        // Giriş butonu
                        Button(action: {
                            Task {
                                await authViewModel.signIn(email: email, password: password)
                            }
                        }) {
                            HStack {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Giriş Yap")
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
                        .disabled(authViewModel.isLoading || email.isEmpty || password.isEmpty)
                        .opacity((authViewModel.isLoading || email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                        .padding(.horizontal, 30)
                        
                        // Kayıt ol bağlantısı
                        Button(action: {
                            showRegister = true
                        }) {
                            HStack(spacing: 4) {
                                Text("Hesabınız yok mu?")
                                    .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
                                Text("Kayıt Ol")
                                    .fontWeight(.semibold)
                                    .foregroundColor(themeViewModel.currentTheme.primaryColor)
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showRegister) {
                RegisterView()
            }
        }
    }
}
