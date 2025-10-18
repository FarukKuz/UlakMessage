//
//  AppTheme.swift
//  UlakMessage
//
//  Konum: Utilities/AppTheme.swift
//

import SwiftUI

enum ThemeType: String, CaseIterable, Codable {
    case light = "Açık Tema"
    case dark = "Koyu Tema"
}

struct AppTheme: Codable {
    var type: ThemeType
    
    // Ana renkler - HEX string olarak
    var primaryColorHex: String // #C913FF (Marka rengi)
    var secondaryColorHex: String // İkinci ana renk
    
    // Arka plan renkleri - HEX string olarak
    var backgroundColorHex: String
    var secondaryBackgroundColorHex: String
    var cardBackgroundColorHex: String
    
    // Metin renkleri - HEX string olarak
    var textColorHex: String
    var secondaryTextColorHex: String
    var placeholderColorHex: String
    
    // Diğer renkler - HEX string olarak
    var borderColorHex: String
    var errorColorHex: String
    var successColorHex: String
    
    // Coding keys
    enum CodingKeys: String, CodingKey {
        case type
        case primaryColorHex = "primaryColor"
        case secondaryColorHex = "secondaryColor"
        case backgroundColorHex = "backgroundColor"
        case secondaryBackgroundColorHex = "secondaryBackgroundColor"
        case cardBackgroundColorHex = "cardBackgroundColor"
        case textColorHex = "textColor"
        case secondaryTextColorHex = "secondaryTextColor"
        case placeholderColorHex = "placeholderColor"
        case borderColorHex = "borderColor"
        case errorColorHex = "errorColor"
        case successColorHex = "successColor"
    }
    
    static let lightTheme = AppTheme(
        type: .light,
        primaryColorHex: "#C913FF",
        secondaryColorHex: "#13D4FF",
        backgroundColorHex: "#FFFFFF",
        secondaryBackgroundColorHex: "#F5F5F5",
        cardBackgroundColorHex: "#FFFFFF",
        textColorHex: "#000000",
        secondaryTextColorHex: "#666666",
        placeholderColorHex: "#999999",
        borderColorHex: "#E0E0E0",
        errorColorHex: "#FF3B30",
        successColorHex: "#34C759"
    )
    
    static let darkTheme = AppTheme(
        type: .dark,
        primaryColorHex: "#C913FF",
        secondaryColorHex: "#13D4FF",
        backgroundColorHex: "#000000",
        secondaryBackgroundColorHex: "#1C1C1E",
        cardBackgroundColorHex: "#2C2C2E",
        textColorHex: "#FFFFFF",
        secondaryTextColorHex: "#EBEBF5",
        placeholderColorHex: "#8E8E93",
        borderColorHex: "#38383A",
        errorColorHex: "#FF453A",
        successColorHex: "#32D74B"
    )
}

// Color extension - Hex string'den Color oluşturma
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // UIColor'a çevir
    func toUIColor() -> UIColor {
        let components = UIColor(self).cgColor.components ?? [0, 0, 0, 1]
        return UIColor(red: components[0], green: components[1], blue: components[2], alpha: components[3])
    }
}

// AppTheme extension - SwiftUI Color'lara çevirme (Computed Properties)
extension AppTheme {
    var primaryColor: Color {
        Color(hex: self.primaryColorHex)
    }
    
    var secondaryColor: Color {
        Color(hex: self.secondaryColorHex)
    }
    
    var backgroundColor: Color {
        Color(hex: self.backgroundColorHex)
    }
    
    var secondaryBackgroundColor: Color {
        Color(hex: self.secondaryBackgroundColorHex)
    }
    
    var cardBackgroundColor: Color {
        Color(hex: self.cardBackgroundColorHex)
    }
    
    var textColor: Color {
        Color(hex: self.textColorHex)
    }
    
    var secondaryTextColor: Color {
        Color(hex: self.secondaryTextColorHex)
    }
    
    var placeholderColor: Color {
        Color(hex: self.placeholderColorHex)
    }
    
    var borderColor: Color {
        Color(hex: self.borderColorHex)
    }
    
    var errorColor: Color {
        Color(hex: self.errorColorHex)
    }
    
    var successColor: Color {
        Color(hex: self.successColorHex)
    }
    
    var colorScheme: ColorScheme {
        type == .light ? .light : .dark
    }
}

// UIColor extension - Hex'e çevirme
extension UIColor {
    func toHex() -> String {
        guard let components = cgColor.components, components.count >= 3 else {
            return "#000000"
        }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        
        return String(format: "#%02lX%02lX%02lX",
                     lroundf(r * 255),
                     lroundf(g * 255),
                     lroundf(b * 255))
    }
}
