import SwiftUI

// MARK: - App Color Palette

enum AppColors {
    // Primary gradients
    static let skyGradient = LinearGradient(
        colors: [Color(hex: 0x4A90D9), Color(hex: 0x1B3A6B)],
        startPoint: .top, endPoint: .bottom
    )
    static let warmGradient = LinearGradient(
        colors: [Color(hex: 0xF2994A), Color(hex: 0xEB5757)],
        startPoint: .leading, endPoint: .trailing
    )
    static let coolGradient = LinearGradient(
        colors: [Color(hex: 0x56CCF2), Color(hex: 0x2F80ED)],
        startPoint: .leading, endPoint: .trailing
    )
    static let tealGradient = LinearGradient(
        colors: [Color(hex: 0x11998E), Color(hex: 0x38EF7D)],
        startPoint: .leading, endPoint: .trailing
    )
    static let purpleGradient = LinearGradient(
        colors: [Color(hex: 0x667EEA), Color(hex: 0x764BA2)],
        startPoint: .leading, endPoint: .trailing
    )

    // Property accent colors
    static let temperature = Color(hex: 0xF2994A)
    static let pressure    = Color(hex: 0x2F80ED)
    static let density     = Color(hex: 0x11998E)
    static let speedSound  = Color(hex: 0x9B51E0)
    static let viscosity   = Color(hex: 0xEB5757)
    static let kinematic   = Color(hex: 0xF2C94C)

    // Layer colors
    static let troposphere  = Color(hex: 0x56CCF2)
    static let tropopause   = Color(hex: 0x6C63FF)
    static let stratosphere = Color(hex: 0x764BA2)
    static let stratopause  = Color(hex: 0x2D1B69)
    static let mesosphere   = Color(hex: 0x1A0F3C)

    // Surface & card
    static let cardBackground = Color(.secondarySystemGroupedBackground)
    static let subtleGlow = Color(hex: 0x4A90D9).opacity(0.08)
}

// MARK: - Hex Color Extension

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}

// MARK: - Glass Card Modifier

struct GlassCard: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

extension View {
    func glassCard(padding: CGFloat = 16) -> some View {
        modifier(GlassCard(padding: padding))
    }
}

// MARK: - Accent Bar Card

struct AccentCard<Content: View>: View {
    let accentColor: Color
    let content: Content

    init(accent: Color, @ViewBuilder content: () -> Content) {
        self.accentColor = accent
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(accentColor.gradient)
                .frame(width: 4)
                .padding(.vertical, 8)

            content
                .padding(.leading, 12)
                .padding(.trailing, 16)
                .padding(.vertical, 12)

            Spacer(minLength: 0)
        }
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Animated Counter Text

struct AnimatedNumber: View {
    let value: Double
    let format: String
    let font: Font

    var body: some View {
        Text(String(format: format, value))
            .font(font)
            .contentTransition(.numericText(value: value))
            .animation(.snappy(duration: 0.3), value: value)
    }
}

// MARK: - Icon Badge

struct IconBadge: View {
    let systemName: String
    let color: Color
    var size: CGFloat = 32

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(color.gradient, in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
    }
}

// MARK: - Layer Info

struct LayerInfo {
    let name: String
    let color: Color
    let altitudeRange: String
    let icon: String

    static func forAltitude(_ h: Double) -> LayerInfo {
        switch h {
        case ..<11_000:
            return LayerInfo(name: "Troposphere", color: AppColors.troposphere, altitudeRange: "0 – 11 km", icon: "cloud.fill")
        case ..<20_000:
            return LayerInfo(name: "Tropopause", color: AppColors.tropopause, altitudeRange: "11 – 20 km", icon: "wind")
        case ..<32_000:
            return LayerInfo(name: "Lower Stratosphere", color: AppColors.stratosphere, altitudeRange: "20 – 32 km", icon: "sun.max.fill")
        case ..<47_000:
            return LayerInfo(name: "Upper Stratosphere", color: AppColors.stratopause, altitudeRange: "32 – 47 km", icon: "sparkles")
        default:
            return LayerInfo(name: "Stratopause", color: AppColors.mesosphere, altitudeRange: "47 – 51 km", icon: "star.fill")
        }
    }
}

// MARK: - Atmosphere Layer Bar

struct AtmosphereLayerBar: View {
    let altitudeMeters: Double
    let maxAltitude: Double = 51_000

    private var progress: Double {
        min(max(altitudeMeters / maxAltitude, 0), 1)
    }

    private let layers: [(color: Color, thickness: Double)] = [
        (AppColors.troposphere,  11_000),
        (AppColors.tropopause,    9_000),
        (AppColors.stratosphere, 12_000),
        (AppColors.stratopause,  15_000),
        (AppColors.mesosphere,    4_000),
    ]

    var body: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width

            ZStack(alignment: .leading) {
                // Layer bands proportional to their real thickness
                HStack(spacing: 0) {
                    ForEach(Array(layers.enumerated()), id: \.offset) { _, layer in
                        layer.color
                            .frame(width: totalWidth * layer.thickness / maxAltitude)
                    }
                }
                .clipShape(Capsule())

                // Position indicator
                Circle()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
                    .frame(width: 12, height: 12)
                    .offset(x: max(0, min(totalWidth - 12, progress * totalWidth - 6)))
                    .animation(.snappy(duration: 0.4), value: progress)
            }
        }
        .frame(height: 12)
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let icon: String
    var color: Color = .primary

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline.bold())
                .foregroundStyle(color)
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.top, 4)
    }
}
