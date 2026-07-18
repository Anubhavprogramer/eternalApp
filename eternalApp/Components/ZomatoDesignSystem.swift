import SwiftUI

extension Color {
    static let zomatoBackground = Color(red: 0.10, green: 0.09, blue: 0.12)
    static let zomatoSurface = Color(red: 0.14, green: 0.13, blue: 0.17)
    static let zomatoSurfaceAlt = Color(red: 0.18, green: 0.16, blue: 0.21)
    static let zomatoAccent = Color(red: 0.95, green: 0.32, blue: 0.38)
    static let zomatoAccentSoft = Color(red: 0.86, green: 0.58, blue: 0.25)
    static let zomatoTextPrimary = Color.white
    static let zomatoTextSecondary = Color.white.opacity(0.72)
}

struct ZomatoBadge: View {
    let text: String
    let icon: String

    var body: some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.white.opacity(0.12), in: Capsule())
            .foregroundStyle(.white)
    }
}

struct ZomatoRoundedButtonStyle: ButtonStyle {
    let background: Color
    let foreground: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(background.opacity(configuration.isPressed ? 0.82 : 1), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .foregroundStyle(foreground)
            .shadow(color: background.opacity(0.25), radius: 16, x: 0, y: 10)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

struct CurrencyText: View {
    let amount: Double
    var isStruckThrough: Bool = false
    var body: some View {
        Text(amount.formatted(.currency(code: "INR").precision(.fractionLength(amount.rounded() == amount ? 0 : 2))))
            .strikethrough(isStruckThrough)
    }
}

struct RemoteFoodImage: View {
    let urlString: String

    var body: some View {
        AsyncImage(url: URL(string: urlString)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                LinearGradient(colors: [Color.orange.opacity(0.45), Color.red.opacity(0.35)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .empty:
                LinearGradient(colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)], startPoint: .topLeading, endPoint: .bottomTrailing)
            @unknown default:
                Color.gray.opacity(0.2)
            }
        }
    }
}
