//
//  LinkableTextView.swift
//  UlakMessage
//
//  Konum: Views/Components/LinkableTextView.swift
//

import SwiftUI
import SafariServices

struct LinkableTextView: View {
    @EnvironmentObject var themeViewModel: ThemeViewModel
    
    let text: String
    let isCurrentUser: Bool
    
    @State private var selectedURL: URL?
    @State private var showSafari = false
    
    private var segments: [TextSegment] {
        LinkDetector.shared.parseTextWithLinks(text: text)
    }
    
    var body: some View {
        Group {
            // Eğer link yoksa normal metin göster
            if segments.count == 1, case .text = segments[0] {
                Text(text)
                    .font(.body)
                    .foregroundColor(isCurrentUser ? .white : themeViewModel.currentTheme.textColor)
            } else {
                // Link içeren metin
                Text(attributedString)
                    .font(.body)
                    .environment(\.openURL, OpenURLAction { url in
                        selectedURL = url
                        showSafari = true
                        return .handled
                    })
            }
        }
        .fullScreenCover(isPresented: $showSafari) {
            if let url = selectedURL {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
    }
    
    private var attributedString: AttributedString {
        var result = AttributedString()
        
        for segment in segments {
            switch segment {
            case .text(let textContent):
                var attrString = AttributedString(textContent)
                attrString.foregroundColor = isCurrentUser ? .white : themeViewModel.currentTheme.textColor
                result.append(attrString)
                
            case .link(let detectedLink):
                var attrString = AttributedString(detectedLink.displayText)
                attrString.link = detectedLink.url
                attrString.foregroundColor = isCurrentUser ? .white : .blue
                attrString.underlineStyle = .single
                result.append(attrString)
            }
        }
        
        return result
    }
}

// MARK: - Safari View Wrapper
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        
        let safari = SFSafariViewController(url: url, configuration: config)
        safari.preferredControlTintColor = UIColor.systemBlue
        safari.dismissButtonStyle = .close
        
        // Kapatma için coordinator ekle
        safari.delegate = context.coordinator
        
        let navigationController = UINavigationController(rootViewController: safari)
        navigationController.isNavigationBarHidden = true
        
        return navigationController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // No update needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        let parent: SafariView
        
        init(parent: SafariView) {
            self.parent = parent
        }
        
        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            parent.dismiss()
        }
    }
}
