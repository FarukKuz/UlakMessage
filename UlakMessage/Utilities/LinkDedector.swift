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
    
    // 🚀 GELİŞMİŞ LINK TESPİTİ
    func detectLinks(in text: String) -> [DetectedLink] {
        var detectedLinks: [DetectedLink] = []
        
        // 1. NSDataDetector ile otomatik tespit
        detectedLinks.append(contentsOf: detectLinksWithDataDetector(in: text))
        
        // 2. Manuel regex ile ek tespit (http/https olmayan linkler için)
        detectedLinks.append(contentsOf: detectLinksWithRegex(in: text))
        
        // Duplikaları temizle ve sırala
        var uniqueLinks: [DetectedLink] = []
        var seenRanges: Set<String> = []
        
        for link in detectedLinks.sorted(by: { $0.range.location < $1.range.location }) {
            let rangeKey = "\(link.range.location)-\(link.range.length)"
            if !seenRanges.contains(rangeKey) {
                uniqueLinks.append(link)
                seenRanges.insert(rangeKey)
            }
        }
        
        return uniqueLinks
    }
    
    // NSDataDetector ile tespit
    private func detectLinksWithDataDetector(in text: String) -> [DetectedLink] {
        var detectedLinks: [DetectedLink] = []
        
        do {
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
            print("❌ Link detection error: \(error)")
        }
        
        return detectedLinks
    }
    
    // Regex ile tespit (www, domain.com gibi linkler için)
    private func detectLinksWithRegex(in text: String) -> [DetectedLink] {
        var detectedLinks: [DetectedLink] = []
        
        // Gelişmiş URL regex pattern
        let patterns = [
            // https:// ve http:// ile başlayanlar
            "https?://[^\\s]+",
            // www. ile başlayanlar
            "www\\.[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\\.[^\\s]+",
            // Direkt domain.com formatı (boşluk veya noktalama işareti ile biten)
            "(?:^|\\s)([a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\\.(com|net|org|edu|gov|io|co|tr|uk|de|fr|jp|cn|ru)[^\\s]*)",
        ]
        
        for pattern in patterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
                let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
                
                for match in matches {
                    var matchRange = match.range
                    var displayText = (text as NSString).substring(with: matchRange)
                    
                    // Baştaki boşlukları temizle
                    displayText = displayText.trimmingCharacters(in: .whitespaces)
                    if displayText.first == " " {
                        matchRange.location += 1
                        matchRange.length -= 1
                    }
                    
                    // URL oluştur
                    var urlString = displayText
                    
                    // http:// veya https:// yoksa ekle
                    if !urlString.lowercased().hasPrefix("http://") && !urlString.lowercased().hasPrefix("https://") {
                        urlString = "https://" + urlString
                    }
                    
                    // URL geçerli mi kontrol et
                    if let url = URL(string: urlString), url.host != nil {
                        let detectedLink = DetectedLink(
                            url: url,
                            range: matchRange,
                            displayText: displayText
                        )
                        detectedLinks.append(detectedLink)
                    }
                }
            } catch {
                print("❌ Regex error: \(error)")
            }
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
        if currentIndex < text.utf16.count {
            let textRange = NSRange(location: currentIndex, length: text.utf16.count - currentIndex)
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
