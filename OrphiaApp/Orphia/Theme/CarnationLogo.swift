import SwiftUI

/// A single petal: an ellipse offset upward from the center of a square frame,
/// then rotated around that frame's center. Mirrors the SVG technique used in the
/// HTML prototype — `<ellipse cx="50" cy="32" rx="18" ry="12" transform="rotate(angle 50 50)"/>`
/// (offset from center, then rotate the whole composition around the shared center point).
private struct Petal: View {
    let frameSize: CGFloat
    let offsetRadius: CGFloat // fraction of frameSize
    let width: CGFloat        // fraction of frameSize
    let height: CGFloat       // fraction of frameSize
    let color: Color
    let angle: Angle

    var body: some View {
        Ellipse()
            .fill(color)
            .frame(width: frameSize * width, height: frameSize * height)
            .offset(y: -frameSize * offsetRadius)
            .frame(width: frameSize, height: frameSize) // wrap so rotation anchors on the flower's center, not the petal's
            .rotationEffect(angle)
    }
}

/// Stylized red carnation logo mark, hand-ported from the HTML prototype's SVG
/// "layered-ellipse rosette": 8 outer petals + 6 inner petals + a gold center dot.
/// `withStem` adds the sage-green stem+leaves used only on the splash/title screen —
/// per branding notes, header/small usages stay stem-less.
struct CarnationLogo: View {
    var size: CGFloat = 34
    var withStem: Bool = false

    private let outerAngles: [Double] = [0, 45, 90, 135, 180, 225, 270, 315]
    private let innerAngles: [Double] = [15, 75, 135, 195, 255, 315]

    var body: some View {
        VStack(spacing: 0) {
            flowerHead
            if withStem {
                stemAndLeaves
            }
        }
    }

    private var flowerHead: some View {
        ZStack {
            ForEach(Array(outerAngles.enumerated()), id: \.offset) { _, a in
                Petal(frameSize: size, offsetRadius: 0.18, width: 0.36, height: 0.24,
                      color: AppColors.carnation, angle: .degrees(a))
            }
            ForEach(Array(innerAngles.enumerated()), id: \.offset) { _, a in
                Petal(frameSize: size, offsetRadius: 0.12, width: 0.26, height: 0.18,
                      color: AppColors.carnationDark, angle: .degrees(a))
            }
            Circle()
                .fill(AppColors.gold)
                .frame(width: size * 0.14, height: size * 0.14)
        }
        .frame(width: size, height: size)
    }

    private var stemAndLeaves: some View {
        ZStack {
            Rectangle()
                .fill(AppColors.stemGreen)
                .frame(width: max(3, size * 0.045), height: size * 0.9)
            HStack(spacing: size * 0.22) {
                Ellipse()
                    .fill(AppColors.stemGreen)
                    .frame(width: size * 0.34, height: size * 0.15)
                    .rotationEffect(.degrees(-28))
                Ellipse()
                    .fill(AppColors.stemGreen)
                    .frame(width: size * 0.34, height: size * 0.15)
                    .rotationEffect(.degrees(28))
            }
            .offset(y: -size * 0.08)
        }
        .frame(width: size, height: size * 0.9)
    }
}
