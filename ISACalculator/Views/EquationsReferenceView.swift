import SwiftUI

struct EquationsReferenceView: View {
    @State private var expandedSections: Set<String> = ["troposphere"]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                    constantsCard
                    equationSection(
                        id: "troposphere",
                        title: String(localized: "Troposphere (0 – 11 km)"),
                        icon: "cloud.fill",
                        color: AppColors.troposphere,
                        equations: troposphereEquations
                    )
                    equationSection(
                        id: "stratosphere",
                        title: String(localized: "Tropopause & Stratosphere (11 – 51 km)"),
                        icon: "sun.max.fill",
                        color: AppColors.stratosphere,
                        equations: stratosphereEquations
                    )
                    equationSection(
                        id: "properties",
                        title: String(localized: "Derived Properties"),
                        icon: "function",
                        color: AppColors.speedSound,
                        equations: derivedEquations
                    )
                    equationSection(
                        id: "density_alt",
                        title: String(localized: "Density Altitude"),
                        icon: "airplane.circle",
                        color: AppColors.pressure,
                        equations: densityAltEquations
                    )
                    equationSection(
                        id: "conversions",
                        title: String(localized: "Altitude Conversions"),
                        icon: "arrow.up.arrow.down",
                        color: AppColors.density,
                        equations: conversionEquations
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemGroupedBackground))
    }

    // MARK: - Constants Card

    private var constantsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: String(localized: "Physical Constants"), icon: "atom", color: .primary)

            VStack(spacing: 6) {
                constantRow("T₀", "288.15 K", "Sea level temperature")
                constantRow("P₀", "101 325 Pa", "Sea level pressure")
                constantRow("ρ₀", "1.225 kg/m³", "Sea level density")
                constantRow("g₀", "9.80665 m/s²", "Standard gravity")
                constantRow("R", "287.05287 J/(kg·K)", "Specific gas constant")
                constantRow("γ", "1.4", "Ratio of specific heats")
                constantRow("λ", "0.0065 K/m", "Tropospheric lapse rate")
                constantRow("r", "6 356 766 m", "Earth radius (geopotential)")
            }
        }
        .padding(14)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    private func constantRow(_ symbol: String, _ value: String, _ desc: String) -> some View {
        HStack(spacing: 8) {
            Text(symbol)
                .font(.system(size: 13, weight: .bold, design: .serif))
                .frame(width: 28, alignment: .trailing)
                .foregroundStyle(AppColors.pressure)
            Text("=")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.system(size: 12, design: .monospaced))
            Spacer()
            Text(desc)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
    }

    // MARK: - Equation Section

    private func equationSection(
        id: String,
        title: String,
        icon: String,
        color: Color,
        equations: [EquationItem]
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (tap to expand/collapse)
            Button {
                withAnimation(.snappy) {
                    if expandedSections.contains(id) {
                        expandedSections.remove(id)
                    } else {
                        expandedSections.insert(id)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    IconBadge(systemName: icon, color: color, size: 28)
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: expandedSections.contains(id) ? "chevron.up" : "chevron.down")
                        .font(.caption.bold())
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)

            if expandedSections.contains(id) {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(equations) { eq in
                        equationCard(eq, color: color)
                    }
                }
                .padding(.top, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(14)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    private func equationCard(_ eq: EquationItem, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Equation name
            Text(eq.name)
                .font(.caption.bold())
                .foregroundStyle(color)

            // Main equation in monospaced serif
            Text(eq.formula)
                .font(.system(size: 15, weight: .medium, design: .serif))
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, alignment: .center)
                .background(color.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))

            // Description
            if let desc = eq.description {
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Conditions
            if let conditions = eq.conditions {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 9))
                    Text(conditions)
                        .font(.system(size: 10))
                }
                .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Equation Data

    private var troposphereEquations: [EquationItem] {
        [
            EquationItem(
                name: String(localized: "Temperature"),
                formula: "T(h) = T₀ − λ · h",
                description: String(localized: "Temperature decreases linearly at 6.5 °C per 1000 m."),
                conditions: "0 ≤ h ≤ 11 000 m"
            ),
            EquationItem(
                name: String(localized: "Pressure"),
                formula: "P(h) = P₀ · (T/T₀)^(g₀/λR)",
                description: String(localized: "Exponent g₀/(λR) = 5.2559. Pressure drops ~12% per 1000 m near sea level."),
                conditions: "g₀/(λR) ≈ 5.2559"
            ),
            EquationItem(
                name: String(localized: "Density"),
                formula: "ρ(h) = ρ₀ · (T/T₀)^(g₀/λR − 1)",
                description: String(localized: "Exponent g₀/(λR) − 1 = 4.2559. Derived from the equation of state."),
                conditions: "g₀/(λR) − 1 ≈ 4.2559"
            ),
        ]
    }

    private var stratosphereEquations: [EquationItem] {
        [
            EquationItem(
                name: String(localized: "Isothermal Layer (Tropopause)"),
                formula: "T = const,  P = Pᵦ · exp(−g₀·Δh / R·T)",
                description: String(localized: "Temperature is constant; pressure decays exponentially with altitude."),
                conditions: "11 000 < h ≤ 20 000 m,  T = 216.65 K"
            ),
            EquationItem(
                name: String(localized: "Gradient Layer (Stratosphere)"),
                formula: "T = Tᵦ + λᵢ·(h − hᵦ),  P = Pᵦ·(T/Tᵦ)^(−g₀/λᵢR)",
                description: String(localized: "Each layer has its own base values (Tᵦ, Pᵦ, hᵦ) and lapse rate λᵢ."),
                conditions: String(localized: "20–32 km: λ = +0.001 K/m\n32–47 km: λ = +0.0028 K/m")
            ),
            EquationItem(
                name: String(localized: "Density (all layers)"),
                formula: "ρ = P / (R · T)",
                description: String(localized: "The ideal gas equation of state holds for the entire ISA."),
                conditions: nil
            ),
        ]
    }

    private var derivedEquations: [EquationItem] {
        [
            EquationItem(
                name: String(localized: "Speed of Sound"),
                formula: "a = √(γ · R · T)",
                description: String(localized: "Depends only on temperature. At sea level a₀ = 340.3 m/s."),
                conditions: "γ = 1.4,  R = 287.05 J/(kg·K)"
            ),
            EquationItem(
                name: String(localized: "Dynamic Viscosity (Sutherland's Law)"),
                formula: "μ = C₁ · T^(3/2) / (T + S)",
                description: String(localized: "Empirical model for the temperature dependence of viscosity."),
                conditions: "C₁ = 1.458 × 10⁻⁶ kg/(m·s·√K),  S = 110.4 K"
            ),
            EquationItem(
                name: String(localized: "Kinematic Viscosity"),
                formula: "ν = μ / ρ",
                description: String(localized: "Increases rapidly with altitude as density decreases."),
                conditions: nil
            ),
        ]
    }

    private var densityAltEquations: [EquationItem] {
        [
            EquationItem(
                name: String(localized: "Density Altitude"),
                formula: "DA: ρ(DA) = P(PA) / (R · T_OAT)",
                description: String(localized: "Find the ISA altitude where standard density equals actual density. Actual density is computed from the pressure at the pressure altitude and the real outside air temperature."),
                conditions: String(localized: "DA > PA when OAT > ISA temp (hot day)\nDA < PA when OAT < ISA temp (cold day)")
            ),
            EquationItem(
                name: String(localized: "Quick Estimate"),
                formula: "DA ≈ PA + 120 · (OAT − T_ISA)",
                description: String(localized: "Rough approximation: each °C above ISA adds ~120 ft to density altitude. Good for pilot mental math."),
                conditions: String(localized: "Valid near sea level; less accurate at high altitudes")
            ),
        ]
    }

    private var conversionEquations: [EquationItem] {
        [
            EquationItem(
                name: String(localized: "Geometric → Geopotential"),
                formula: "h_gp = (r · h_geo) / (r + h_geo)",
                description: String(localized: "ISA is defined in geopotential altitude. The difference is ~16 m at 10 km."),
                conditions: "r = 6 356 766 m"
            ),
            EquationItem(
                name: String(localized: "Geopotential → Geometric"),
                formula: "h_geo = (r · h_gp) / (r − h_gp)",
                description: String(localized: "Inverse conversion. Geometric altitude is always slightly larger."),
                conditions: nil
            ),
        ]
    }
}

// MARK: - Equation Model

struct EquationItem: Identifiable {
    let id = UUID()
    let name: String
    let formula: String
    let description: String?
    let conditions: String?
}

#Preview {
    EquationsReferenceView()
}
