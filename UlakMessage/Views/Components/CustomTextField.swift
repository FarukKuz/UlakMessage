//
//  CustomTextField.swift
//  UlakMessage
//
//  Konum: Views/Components/CustomTextField.swift
//

import SwiftUI

struct CustomTextField: View {
    @EnvironmentObject var themeViewModel: ThemeViewModel
    
    let title: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var icon: String? = nil
    
    @State private var isPasswordVisible = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(themeViewModel.currentTheme.textColor)
            
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
                        .frame(width: 20)
                }
                
                if isSecure && !isPasswordVisible {
                    SecureField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .foregroundColor(themeViewModel.currentTheme.textColor)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .autocapitalization(.none)
                        .foregroundColor(themeViewModel.currentTheme.textColor)
                }
                
                if isSecure {
                    Button(action: {
                        isPasswordVisible.toggle()
                    }) {
                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
                    }
                }
            }
            .padding()
            .background(themeViewModel.currentTheme.cardBackgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(themeViewModel.currentTheme.borderColor, lineWidth: 1)
            )
        }
    }
}
