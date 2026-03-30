import SwiftUI

enum PopLexTheme {
    static let backgroundTop = Color(red: 1.0, green: 0.95, blue: 0.64)
    static let backgroundMid = Color(red: 0.89, green: 0.96, blue: 1.0)
    static let backgroundBottom = Color(red: 1.0, green: 0.85, blue: 0.89)
    static let primaryPink = Color(red: 1.0, green: 0.36, blue: 0.63)
    static let primaryBlue = Color(red: 0.12, green: 0.63, blue: 0.98)
    static let primaryOrange = Color(red: 1.0, green: 0.58, blue: 0.25)
    static let ink = Color(red: 0.13, green: 0.12, blue: 0.24)

    static func chipColor(for languageID: String) -> Color {
        switch languageID {
        case "zh", "bn":
            return primaryOrange
        case "es", "pt":
            return primaryPink
        case "ar", "ur":
            return Color(red: 0.39, green: 0.46, blue: 0.96)
        default:
            return primaryBlue
        }
    }
}

struct PopLexBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [PopLexTheme.backgroundTop, PopLexTheme.backgroundMid, PopLexTheme.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(PopLexTheme.primaryPink.opacity(0.24))
                .frame(width: 260, height: 260)
                .blur(radius: 14)
                .offset(x: 130, y: -280)

            Circle()
                .fill(PopLexTheme.primaryBlue.opacity(0.18))
                .frame(width: 300, height: 300)
                .blur(radius: 16)
                .offset(x: -150, y: 210)

            Circle()
                .fill(PopLexTheme.primaryOrange.opacity(0.24))
                .frame(width: 180, height: 180)
                .blur(radius: 8)
                .offset(x: -120, y: -260)
        }
        .ignoresSafeArea()
    }
}

struct PopLexSurface<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.6), lineWidth: 1)
            }
            .shadow(color: PopLexTheme.primaryBlue.opacity(0.12), radius: 18, y: 8)
    }
}

struct ConceptStickerView: View {
    let title: String
    let tint: Color

    private var symbolName: String {
        let symbols = [
            "sparkles",
            "text.book.closed.fill",
            "globe.europe.africa.fill",
            "star.bubble.fill",
            "brain.head.profile",
            "bolt.badge.clock.fill"
        ]
        let index = abs(title.hashValue) % symbols.count
        return symbols[index]
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [tint.opacity(0.95), PopLexTheme.primaryOrange.opacity(0.92)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(.white.opacity(0.18))
                .frame(width: 120, height: 120)
                .offset(x: 70, y: -55)

            Circle()
                .fill(.white.opacity(0.12))
                .frame(width: 90, height: 90)
                .offset(x: -90, y: 70)

            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: symbolName)
                    .font(.system(size: 42, weight: .black))
                    .foregroundStyle(.white)

                Text(title)
                    .font(.custom("AvenirNext-Bold", size: 28))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(22)
        }
    }
}
