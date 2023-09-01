#if os(macOS)
import AppKit
#else
import UIKit
#endif

fileprivate struct FontDescriptor: Hashable {
    let fontFamily: String
    let isItalic: Bool
    let isBold: Bool
}

final class FontHelpers {
    
    fileprivate static var fonts: [FontDescriptor: String] = [:]
    
    class func fontName(with fontFamily: String, italic: Bool, bold: Bool) -> String? {
        let fontDescriptor = FontDescriptor(fontFamily: fontFamily, isItalic: italic, isBold: bold)
        if let existingFontName = fonts[fontDescriptor] {
            return existingFontName
        }
        
        guard let fontName = getFontName(fontDescriptor) else { return nil }
        
        fonts[fontDescriptor] = fontName
        return fontName
    }
    
    #if os(macOS)
    
    fileprivate class func getFontName(_ fontDescriptor: FontDescriptor) -> String? {
        var traits: NSFontTraitMask = []
        if fontDescriptor.isItalic {
            traits.insert(.italicFontMask)
        }
        if fontDescriptor.isBold {
            traits.insert(.boldFontMask)
        }
        let font = NSFontManager.shared.font(withFamily: fontDescriptor.fontFamily, traits: traits, weight: 5, size: 12)
        return font?.fontName
    }
    
    #else
    
    fileprivate class func getFontName(_ fontDescriptor: FontDescriptor) -> String? {
        var descriptor = UIFontDescriptor().withFamily(fontDescriptor.fontFamily)
        if fontDescriptor.isBold || fontDescriptor.isItalic {
            var traits: UIFontDescriptor.SymbolicTraits = []
            if (fontDescriptor.isItalic) {
                traits.insert(.traitItalic)
            }
            if (fontDescriptor.isBold) {
                traits.insert(.traitBold)
            }
            if let newDescriptor = descriptor.withSymbolicTraits(traits) {
                descriptor = newDescriptor
            }
        }
        let font = UIFont(descriptor: descriptor, volumeSize: 12)
        return font.fontName
    }
    
    #endif
    
}
