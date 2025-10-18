//
//  ColorPickerView.swift
//  UlakMessage
//
//  Konum: Views/Components/ColorPickerView.swift
//

import SwiftUI

struct ColorPickerRow: View {
    @EnvironmentObject var themeViewModel: ThemeViewModel
    
    let title: String
    let colorType: ThemeManager.ColorType
    @Binding var hexColor: String
    @State private var selectedColor: Color
    @State private var showColorPicker = false
    
    init(title: String, colorType: ThemeManager.ColorType, hexColor: Binding<String>) {
        self.title = title
        self.colorType = colorType
        self._hexColor = hexColor
        self._selectedColor = State(initialValue: Color(hex: hexColor.wrappedValue))
    }
    
    var body: some View {
        Button(action: {
            showColorPicker = true
        }) {
            HStack {
                Text(title)
                    .foregroundColor(themeViewModel.currentTheme.textColor)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text(hexColor.uppercased())
                        .font(.caption)
                        .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
                    
                    Circle()
                        .fill(Color(hex: hexColor))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Circle()
                                .stroke(themeViewModel.currentTheme.borderColor, lineWidth: 1)
                        )
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
            }
        }
        .sheet(isPresented: $showColorPicker) {
            ColorPickerSheet(
                title: title,
                selectedColor: $selectedColor,
                hexColor: $hexColor,
                colorType: colorType
            )
        }
        .onChange(of: hexColor) { oldValue, newValue in
            selectedColor = Color(hex: newValue)
        }
    }
}

struct ColorPickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeViewModel: ThemeViewModel
    
    let title: String
    @Binding var selectedColor: Color
    @Binding var hexColor: String
    let colorType: ThemeManager.ColorType
    
    @State private var tempColor: Color
    @State private var tempHex: String
    
    init(title: String, selectedColor: Binding<Color>, hexColor: Binding<String>, colorType: ThemeManager.ColorType) {
        self.title = title
        self._selectedColor = selectedColor
        self._hexColor = hexColor
        self.colorType = colorType
        self._tempColor = State(initialValue: selectedColor.wrappedValue)
        self._tempHex = State(initialValue: hexColor.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                themeViewModel.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Renk önizlemesi
                    VStack(spacing: 15) {
                        Circle()
                            .fill(tempColor)
                            .frame(width: 120, height: 120)
                            .shadow(color: tempColor.opacity(0.3), radius: 20, x: 0, y: 10)
                        
                        Text(tempHex.uppercased())
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(themeViewModel.currentTheme.textColor)
                    }
                    .padding(.top, 30)
                    
                    // Renk seçici
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Renk Seçin")
                            .font(.headline)
                            .foregroundColor(themeViewModel.currentTheme.textColor)
                            .padding(.horizontal)
                        
                        ColorPicker("", selection: $tempColor, supportsOpacity: false)
                            .labelsHidden()
                            .padding()
                            .background(themeViewModel.currentTheme.cardBackgroundColor)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .onChange(of: tempColor) { oldValue, newValue in
                                tempHex = newValue.toUIColor().toHex()
                            }
                    }
                    
                    // Önceden tanımlı renkler
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Hızlı Seçim")
                            .font(.headline)
                            .foregroundColor(themeViewModel.currentTheme.textColor)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                PresetColorButton(color: Color(hex: "#C913FF"), title: "Mor", isSelected: tempHex.uppercased() == "#C913FF") {
                                    selectPresetColor("#C913FF")
                                }
                                
                                PresetColorButton(color: Color(hex: "#13D4FF"), title: "Turkuaz", isSelected: tempHex.uppercased() == "#13D4FF") {
                                    selectPresetColor("#13D4FF")
                                }
                                
                                PresetColorButton(color: Color(hex: "#FF6B6B"), title: "Kırmızı", isSelected: tempHex.uppercased() == "#FF6B6B") {
                                    selectPresetColor("#FF6B6B")
                                }
                                
                                PresetColorButton(color: Color(hex: "#4ECDC4"), title: "Yeşil", isSelected: tempHex.uppercased() == "#4ECDC4") {
                                    selectPresetColor("#4ECDC4")
                                }
                                
                                PresetColorButton(color: Color(hex: "#FFD93D"), title: "Sarı", isSelected: tempHex.uppercased() == "#FFD93D") {
                                    selectPresetColor("#FFD93D")
                                }
                                
                                PresetColorButton(color: Color(hex: "#FF9FF3"), title: "Pembe", isSelected: tempHex.uppercased() == "#FF9FF3") {
                                    selectPresetColor("#FF9FF3")
                                }
                                
                                PresetColorButton(color: Color(hex: "#54A0FF"), title: "Mavi", isSelected: tempHex.uppercased() == "#54A0FF") {
                                    selectPresetColor("#54A0FF")
                                }
                                
                                PresetColorButton(color: Color(hex: "#FF6348"), title: "Turuncu", isSelected: tempHex.uppercased() == "#FF6348") {
                                    selectPresetColor("#FF6348")
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                    .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        selectedColor = tempColor
                        hexColor = tempHex
                        themeViewModel.updateColor(colorType: colorType, hexColor: tempHex)
                        dismiss()
                    }
                    .foregroundColor(themeViewModel.currentTheme.primaryColor)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func selectPresetColor(_ hex: String) {
        tempHex = hex
        tempColor = Color(hex: hex)
    }
}

struct PresetColorButton: View {
    @EnvironmentObject var themeViewModel: ThemeViewModel
    
    let color: Color
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? themeViewModel.currentTheme.primaryColor : themeViewModel.currentTheme.borderColor, lineWidth: isSelected ? 3 : 1)
                    )
                    .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 2)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(themeViewModel.currentTheme.textColor)
            }
        }
    }
}
