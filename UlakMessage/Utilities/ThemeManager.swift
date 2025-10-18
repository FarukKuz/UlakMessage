//
//  ThemeManager.swift
//  UlakMessage
//
//  Konum: Utilities/ThemeManager.swift
//

import Foundation
import SwiftUI

class ThemeManager {
    static let shared = ThemeManager()
    
    private let userDefaults = UserDefaults.standard
    private let themeKey = "selectedTheme"
    private let customThemesKey = "customThemes"
    
    private init() {}
    
    // Mevcut temayı kaydet
    func saveTheme(_ theme: AppTheme) {
        if let encoded = try? JSONEncoder().encode(theme) {
            userDefaults.set(encoded, forKey: themeKey)
        }
    }
    
    // Kaydedilmiş temayı yükle
    func loadTheme() -> AppTheme {
        guard let data = userDefaults.data(forKey: themeKey),
              let theme = try? JSONDecoder().decode(AppTheme.self, from: data) else {
            // Varsayılan olarak açık tema
            return .lightTheme
        }
        return theme
    }
    
    // Özel tema kaydet
    func saveCustomTheme(_ theme: AppTheme, name: String) {
        var customThemes = loadCustomThemes()
        customThemes[name] = theme
        
        if let encoded = try? JSONEncoder().encode(customThemes) {
            userDefaults.set(encoded, forKey: customThemesKey)
        }
    }
    
    // Özel temaları yükle
    func loadCustomThemes() -> [String: AppTheme] {
        guard let data = userDefaults.data(forKey: customThemesKey),
              let themes = try? JSONDecoder().decode([String: AppTheme].self, from: data) else {
            return [:]
        }
        return themes
    }
    
    // Tema rengini güncelle
    func updateThemeColor(for theme: inout AppTheme, colorType: ColorType, hexColor: String) {
        switch colorType {
        case .primary:
            theme.primaryColorHex = hexColor
        case .secondary:
            theme.secondaryColorHex = hexColor
        case .background:
            theme.backgroundColorHex = hexColor
        case .secondaryBackground:
            theme.secondaryBackgroundColorHex = hexColor
        case .cardBackground:
            theme.cardBackgroundColorHex = hexColor
        case .text:
            theme.textColorHex = hexColor
        case .secondaryText:
            theme.secondaryTextColorHex = hexColor
        case .placeholder:
            theme.placeholderColorHex = hexColor
        case .border:
            theme.borderColorHex = hexColor
        case .error:
            theme.errorColorHex = hexColor
        case .success:
            theme.successColorHex = hexColor
        }
    }
    
    enum ColorType {
        case primary, secondary, background, secondaryBackground, cardBackground
        case text, secondaryText, placeholder, border, error, success
    }
}
