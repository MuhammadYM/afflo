import SwiftUI

enum TextVariant {
    case title
    case subtitle
    case `default`
    case defaultSemiBold
    case link
}

struct ThemedText: View {
    @Environment(\.colorScheme) var colorScheme

    let text: String
    let variant: TextVariant

    init(_ text: String, variant: TextVariant = .default) {
        self.text = text
        self.variant = variant
    }

    var body: some View {
        Text(text)
            .font(font)
            .foregroundColor(textColor)
    }

    private var font: Font {
        switch variant {
        case .title:
            return .affloTitle
        case .subtitle:
            return .affloSubtitle
        case .default:
            return .affloDefault
        case .defaultSemiBold:
            return .affloDefaultSemiBold
        case .link:
            return .affloLink
        }
    }

    private var textColor: Color {
        switch variant {
        case .link:
            return Color.tint(for: colorScheme)
        default:
            return Color.text(for: colorScheme)
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        ThemedText("Title Text", variant: .title)
        ThemedText("Subtitle Text", variant: .subtitle)
        ThemedText("Default Text", variant: .default)
        ThemedText("Default SemiBold Text", variant: .defaultSemiBold)
        ThemedText("Link Text", variant: .link)
    }
    .padding()
}
