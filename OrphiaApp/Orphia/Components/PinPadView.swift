import SwiftUI

/// Dot indicator showing PIN length without ever displaying the digits.
struct PinDotsView: View {
    let filledCount: Int
    let total: Int = 4

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .strokeBorder(AppColors.primary, lineWidth: 2)
                    .background(Circle().fill(i < filledCount ? AppColors.primary : Color.clear))
                    .frame(width: 16, height: 16)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }
}

/// Numeric PIN pad: large tap targets instead of a QWERTY keyboard, matching the
/// HTML prototype's reasoning (easier to tap accurately, no shift/caps confusion).
struct PinPadView: View {
    @Binding var pin: String
    let maxDigits: Int = 4

    private let keys: [String] = ["1","2","3","4","5","6","7","8","9","","0","⌫"]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
            ForEach(Array(keys.enumerated()), id: \.offset) { _, key in
                if key.isEmpty {
                    Color.clear.frame(height: 54)
                } else {
                    Button(action: { handle(key) }) {
                        Text(key)
                            .font(.system(size: 22, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppColors.border, lineWidth: 2))
                            .cornerRadius(14)
                    }
                    .foregroundColor(AppColors.ink)
                }
            }
        }
    }

    private func handle(_ key: String) {
        if key == "⌫" {
            if !pin.isEmpty { pin.removeLast() }
        } else if pin.count < maxDigits {
            pin.append(key)
        }
    }
}
