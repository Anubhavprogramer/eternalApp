import SwiftUI

// MARK: - Animated Gradient Background

struct AnimatedGradientBackground: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                // Base dark fill
                ctx.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .color(Color(red: 0.08, green: 0.07, blue: 0.10))
                )

                // Blob 1 — red, drifts diagonally
                let b1x = size.width  * (0.20 + 0.30 * sin(t * 0.18))
                let b1y = size.height * (0.20 + 0.25 * cos(t * 0.14))
                ctx.fill(
                    Path(ellipseIn: CGRect(x: b1x - 160, y: b1y - 160, width: 320, height: 320)),
                    with: .color(Color(red: 0.90, green: 0.22, blue: 0.28).opacity(0.28))
                )

                // Blob 2 — orange, opposite phase
                let b2x = size.width  * (0.75 + 0.22 * cos(t * 0.13))
                let b2y = size.height * (0.65 + 0.20 * sin(t * 0.17))
                ctx.fill(
                    Path(ellipseIn: CGRect(x: b2x - 180, y: b2y - 180, width: 360, height: 360)),
                    with: .color(Color(red: 0.80, green: 0.30, blue: 0.10).opacity(0.20))
                )

                // Blob 3 — purple, slow, top-right
                let b3x = size.width  * (0.80 + 0.12 * sin(t * 0.09))
                let b3y = size.height * (0.12 + 0.14 * cos(t * 0.11))
                ctx.fill(
                    Path(ellipseIn: CGRect(x: b3x - 120, y: b3y - 120, width: 240, height: 240)),
                    with: .color(Color(red: 0.40, green: 0.15, blue: 0.55).opacity(0.18))
                )
            }
            .blur(radius: 60)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Typewriter Text

struct TypewriterText: View {
    let fullText: String
    let font: Font
    var delay: Double        = 0.0
    var charInterval: Double = 0.045   // time between each character typed
    var pauseAfterFinish: Double = 1.2 // hold at full string before erasing
    var eraseInterval: Double = 0.025  // time between each character erased

    @State private var displayed: String = ""

    var body: some View {
        Text(displayed)
            .font(font)
            .onAppear { scheduleNextCycle(initialDelay: delay) }
    }

    // MARK: - Cycle

    private func scheduleNextCycle(initialDelay: Double) {
        displayed = ""
        typeChar(index: 0, startDelay: initialDelay)
    }

    private func typeChar(index: Int, startDelay: Double) {
        let chars = Array(fullText)
        guard index < chars.count else {
            // Finished — pause then erase
            DispatchQueue.main.asyncAfter(deadline: .now() + startDelay + pauseAfterFinish) {
                eraseChar(from: chars.count - 1)
            }
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + startDelay + Double(index) * charInterval) {
            displayed.append(chars[index])
            typeChar(index: index + 1, startDelay: startDelay)
        }
    }

    private func eraseChar(from index: Int) {
        guard index >= 0 else {
            // Fully erased — brief gap then restart
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                scheduleNextCycle(initialDelay: 0)
            }
            return
        }
        DispatchQueue.main.asyncAfter(
            deadline: .now() + Double(Array(fullText).count - 1 - index) * eraseInterval
        ) {
            if !displayed.isEmpty { displayed.removeLast() }
            eraseChar(from: index - 1)
        }
    }
}

// MARK: - Waveform View

struct WaveformView: View {
    let level: CGFloat   // 0–1

    private let barCount = 7

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0 ..< barCount, id: \.self) { i in
                Capsule()
                    .fill(Color.zomatoAccent.opacity(0.85))
                    .frame(width: 4, height: barHeight(for: i))
                    .animation(
                        .spring(response: 0.22, dampingFraction: 0.55)
                            .delay(Double(i) * 0.03),
                        value: level
                    )
            }
        }
        .frame(height: 40)
    }

    private func barHeight(for index: Int) -> CGFloat {
        let centre   = Double(barCount - 1) / 2.0
        let distance = abs(Double(index) - centre)
        let shape    = 1.0 - (distance / centre) * 0.5  // tallest at centre
        let base: CGFloat = 6
        let maxH: CGFloat = 38
        return base + (maxH - base) * level * CGFloat(shape)
    }
}
