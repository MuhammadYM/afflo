import SwiftUI

// MARK: - Typography Styles
struct Typography {
    // Font sizes matching React Native (32, 20, 16)
    static let titleSize: CGFloat = 32
    static let subtitleSize: CGFloat = 20
    static let defaultSize: CGFloat = 16

    // Font names for Anonymous Pro
    static let regular = "AnonymousPro-Regular"
    static let bold = "AnonymousPro-Bold"
    static let italic = "AnonymousPro-Italic"
    static let boldItalic = "AnonymousPro-BoldItalic"
}

// MARK: - Font Extension
extension Font {
    static func anonymousPro(size: CGFloat = Typography.defaultSize, weight: Font.Weight = .regular) -> Font {
        let fontName: String
        switch weight {
        case .bold:
            fontName = Typography.bold
        default:
            fontName = Typography.regular
        }
        return .custom(fontName, size: size)
    }

    static var affloTitle: Font {
        .custom(Typography.bold, size: Typography.titleSize)
    }

    static var affloSubtitle: Font {
        .custom(Typography.bold, size: Typography.subtitleSize)
    }

    static var affloDefault: Font {
        .custom(Typography.regular, size: Typography.defaultSize)
    }

    static var affloDefaultSemiBold: Font {
        .custom(Typography.bold, size: Typography.defaultSize)
    }

    static var affloLink: Font {
        .custom(Typography.regular, size: Typography.defaultSize)
    }
}
