import SwiftUI

/// Mirrors `.btn-primary` from the HTML prototype: solid warm-red fill, large tap target.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 19, weight: .semibold))
            .frame(maxWidth: .infinity, minHeight: 56)
            .foregroundColor(.white)
            .background(AppColors.primary)
            .cornerRadius(16)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

/// Mirrors `.btn-secondary`: white fill, colored border/text.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 19, weight: .semibold))
            .frame(maxWidth: .infinity, minHeight: 56)
            .foregroundColor(AppColors.primaryDark)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.primary, lineWidth: 2)
            )
            .cornerRadius(16)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

/// Mirrors `.btn-ghost`: text-only, underlined, muted — used for "Back"/"Discard".
struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15))
            .underline()
            .foregroundColor(AppColors.muted)
            .frame(maxWidth: .infinity, minHeight: 40)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
