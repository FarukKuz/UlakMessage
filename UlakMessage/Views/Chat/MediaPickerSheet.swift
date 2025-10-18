//
//  MediaPickerSheet.swift
//  UlakMessage
//
//  Konum: Views/Chat/MediaPickerSheet.swift
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

enum MediaPickerType {
    case photo
    case video
    case document
    case audio
    case location
}

struct MediaPickerSheet: View {
    @EnvironmentObject var themeViewModel: ThemeViewModel
    @Environment(\.dismiss) var dismiss
    
    let onSelect: (MediaPickerType) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Başlık
            HStack {
                Text("Dosya Gönder")
                    .font(.headline)
                    .foregroundColor(themeViewModel.currentTheme.textColor)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
                }
            }
            .padding()
            
            Divider()
                .background(themeViewModel.currentTheme.borderColor)
            
            // Seçenekler
            ScrollView {
                VStack(spacing: 12) {
                    // Fotoğraf
                    MediaOptionCard(
                        icon: "photo.on.rectangle.angled",
                        title: "Fotoğraf",
                        description: "Galeriden fotoğraf seç",
                        color: .blue,
                        action: {
                            onSelect(.photo)
                            dismiss()
                        }
                    )
                    
                    // Video
                    MediaOptionCard(
                        icon: "video.fill",
                        title: "Video",
                        description: "Galeriden video seç",
                        color: .purple,
                        action: {
                            onSelect(.video)
                            dismiss()
                        }
                    )
                    
                    // Belge
                    MediaOptionCard(
                        icon: "doc.fill",
                        title: "Belge",
                        description: "PDF, Word, Excel vb.",
                        color: .orange,
                        action: {
                            onSelect(.document)
                            dismiss()
                        }
                    )
                    
                    // Ses Kaydı
                    MediaOptionCard(
                        icon: "waveform",
                        title: "Ses Kaydı",
                        description: "Sesli mesaj kaydet",
                        color: .red,
                        action: {
                            onSelect(.audio)
                            dismiss()
                        }
                    )
                    
                    // Konum
                    MediaOptionCard(
                        icon: "location.fill",
                        title: "Konum",
                        description: "Konumumu paylaş",
                        color: .green,
                        action: {
                            onSelect(.location)
                            dismiss()
                        }
                    )
                }
                .padding()
            }
        }
        .background(themeViewModel.currentTheme.backgroundColor)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// Medya seçenek kartı
struct MediaOptionCard: View {
    @EnvironmentObject var themeViewModel: ThemeViewModel
    
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
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
                        .font(.headline)
                        .foregroundColor(themeViewModel.currentTheme.textColor)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(themeViewModel.currentTheme.secondaryTextColor)
            }
            .padding()
            .background(themeViewModel.currentTheme.cardBackgroundColor)
            .cornerRadius(15)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
