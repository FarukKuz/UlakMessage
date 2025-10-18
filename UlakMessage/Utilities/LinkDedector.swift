//
//  LinkDetector.swift
//  UlakMessage
//
//  Konum: Utilities/LinkDetector.swift
//

import Foundation

struct DetectedLink: Identifiable {
    let id = UUID()
    let url: URL
    let range: NSRange
    let displayText: String
}

class LinkDetector {
    static let shared = LinkDetector()
    
    private init() {}
    
    // Metindeki linkleri tespit et
    func detectLinks(in text: String) -> [DetectedLink] {
        var detectedLinks: [DetectedLink] = []
        
        do {
            // URL regex pattern
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
            
            for match in matches {
                if let url = match.url {
                    let displayText = (text as NSString).substring(with: match.range)
                    let detectedLink = DetectedLink(
                        url: url,
                        range: match.range,
                        displayText: displayText
                    )
                    detectedLinks.append(detectedLink)
                }
            }
        } catch {
            print("Link detection error: \(error)")
        }
        
        return detectedLinks
    }
    
    // Metni parçalara ayır (metin ve linkler)
    func parseTextWithLinks(text: String) -> [TextSegment] {
        let links = detectLinks(in: text)
        
        guard !links.isEmpty else {
            return [.text(text)]
        }
        
        var segments: [TextSegment] = []
        var currentIndex = 0
        
        for link in links.sorted(by: { $0.range.location < $1.range.location }) {
            // Link öncesindeki metin
            if link.range.location > currentIndex {
                let textRange = NSRange(location: currentIndex, length: link.range.location - currentIndex)
                let textPart = (text as NSString).substring(with: textRange)
                if !textPart.isEmpty {
                    segments.append(.text(textPart))
                }
            }
            
            // Link
            segments.append(.link(link))
            currentIndex = link.range.location + link.range.length
        }
        
        // Son kısımdaki metin
        if currentIndex < text.count {
            let textRange = NSRange(location: currentIndex, length: text.count - currentIndex)
            let textPart = (text as NSString).substring(with: textRange)
            if !textPart.isEmpty {
                segments.append(.text(textPart))
            }
        }
        
        return segments
    }
}

// Metin segmentleri
enum TextSegment: Identifiable {
    case text(String)
    case link(DetectedLink)
    
    var id: String {
        switch self {
        case .text(let text):
            return "text_\(text.hashValue)"
        case .link(let link):
            return "link_\(link.id.uuidString)"
        }
    }
}
