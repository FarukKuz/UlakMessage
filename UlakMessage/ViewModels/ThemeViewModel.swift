//
//  ThemeViewModel.swift
//  UlakMessage
//
//  Konum: ViewModels/ThemeViewModel.swift
//

import SwiftUI
import Combine

class ThemeViewModel: ObservableObject {
    @Published var currentTheme: AppTheme
    @Published var customThemes: [String: AppTheme] = [:]
    
    private let themeManager = ThemeManager.shared
    
    init() {
        self.currentTheme = themeManager.loadTheme()
        self.customThemes = themeManager.loadCustomThemes()
    }
    
    // Tema değiştir
    func switchTheme(to type: ThemeType) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentTheme = type == .light ? .lightTheme : .darkTheme
            themeManager.saveTheme(currentTheme)
        }
    }
    
    // Özel tema uygula
    func applyCustomTheme(named name: String) {
        guard let theme = customThemes[name] else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentTheme = theme
            themeManager.saveTheme(currentTheme)
        }
    }
    
    // Renk güncelle
    func updateColor(colorType: ThemeManager.ColorType, hexColor: String) {
        themeManager.updateThemeColor(for: &currentTheme, colorType: colorType, hexColor: hexColor)
        themeManager.saveTheme(currentTheme)
    }
    
    // Özel tema kaydet
    func saveCustomTheme(name: String) {
        themeManager.saveCustomTheme(currentTheme, name: name)
        customThemes = themeManager.loadCustomThemes()
    }
}
